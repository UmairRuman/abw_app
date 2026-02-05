// lib/features/cart/data/collections/carts_collection.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';
import '../models/cart_item_model.dart';

class CartsCollection {
  // Singleton pattern
  static final CartsCollection instance = CartsCollection._internal();
  CartsCollection._internal();

  factory CartsCollection() {
    return instance;
  }

  static final _cartsCollection = FirebaseFirestore.instance.collection(
    'carts',
  );

  /// Get user's cart (or return empty cart)
  Future<CartModel> getCart(String userId) async {
    try {
      final snapshot = await _cartsCollection.doc(userId).get();

      if (snapshot.exists && snapshot.data() != null) {
        return CartModel.fromJson(snapshot.data()!);
      }

      // Return empty cart if doesn't exist
      log('Cart not found for user: $userId, returning empty cart');
      return CartModel.empty(userId);
    } on FirebaseException catch (e) {
      log('Firebase Error getting cart: ${e.code} - ${e.message}');
      return CartModel.empty(userId);
    } catch (e) {
      log('Error getting cart: ${e.toString()}');
      return CartModel.empty(userId);
    }
  }

  Future<bool> addItemToCart(String userId, CartItemModel item) async {
    try {
      final cartDoc = await _cartsCollection.doc(userId).get();

      if (cartDoc.exists) {
        final cartData = cartDoc.data()!;
        final currentStoreId = cartData['storeId'] as String?;

        // ✅ CHECK IF DIFFERENT STORE
        if (currentStoreId != null && currentStoreId != item.storeId) {
          // Don't throw exception, return false to handle in provider
          return false;
        }

        // Same store or empty cart - proceed
        final items = List<Map<String, dynamic>>.from(
          cartData['items'] as List? ?? [],
        );

        // Check if item already exists
        final existingIndex = items.indexWhere(
          (i) => i['productId'] == item.productId,
        );

        if (existingIndex >= 0) {
          // Update quantity
          items[existingIndex]['quantity'] =
              (items[existingIndex]['quantity'] as int) + item.quantity;
          items[existingIndex]['total'] =
              items[existingIndex]['quantity'] * item.discountedPrice;
        } else {
          // Add new item
          items.add(item.toJson());
        }

        // Calculate totals
        double subtotal = 0;
        int totalItems = 0;
        for (var item in items) {
          subtotal += (item['total'] as num).toDouble();
          totalItems += (item['quantity'] as int);
        }

        await _cartsCollection.doc(userId).update({
          'items': items,
          'subtotal': subtotal,
          'total': subtotal + (cartData['deliveryFee'] as num).toDouble(),
          'totalItems': totalItems,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      } else {
        // Create new cart
        final cart = CartModel(
          userId: userId,
          storeId: item.storeId,
          storeName: item.storeName,
          items: [item],
          subtotal: item.total,
          deliveryFee: 50.0, // TODO: Get from store
          discount: 0,
          total: item.total + 50.0,
          totalItems: item.quantity,

          updatedAt: DateTime.now(),
        );

        await _cartsCollection.doc(userId).set(cart.toJson());
        return true;
      }
    } catch (e) {
      log('Error adding item to cart: ${e.toString()}');
      rethrow;
    }
  }

  /// Update item quantity
  Future<bool> updateItemQuantity(
    String userId,
    String productId,
    int newQuantity,
  ) async {
    try {
      final cart = await getCart(userId);

      if (cart.isEmpty) {
        log('Cart is empty');
        return false;
      }

      final itemIndex = cart.items.indexWhere(
        (item) => item.productId == productId,
      );

      if (itemIndex == -1) {
        log('Item not found in cart: $productId');
        return false;
      }

      // VALIDATION: Check quantity limits
      if (newQuantity < 1) {
        log('Quantity must be at least 1');
        return false;
      }

      final item = cart.items[itemIndex];
      if (newQuantity > item.maxQuantity) {
        log('Quantity exceeds maximum: ${item.maxQuantity}');
        throw Exception('Maximum quantity is ${item.maxQuantity}');
      }

      // Update item
      List<CartItemModel> updatedItems = List.from(cart.items);
      updatedItems[itemIndex] = item.copyWith(
        quantity: newQuantity,
        total:
            (item.discountedPrice > 0 ? item.discountedPrice : item.price) *
            newQuantity,
      );

      // Recalculate totals
      final newSubtotal = updatedItems.fold<double>(
        0.0,
        (sum, item) => sum + item.total,
      );
      final newTotalItems = updatedItems.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );

      final updatedCart = cart.copyWith(
        items: updatedItems,
        totalItems: newTotalItems,
        subtotal: newSubtotal,
        total: newSubtotal + cart.deliveryFee - cart.discount,
        updatedAt: DateTime.now(),
      );

      await _cartsCollection.doc(userId).update(updatedCart.toJson());

      log('Item quantity updated: $productId -> $newQuantity');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error updating quantity: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error updating quantity: ${e.toString()}');
      rethrow;
    }
  }

  /// Remove item from cart
  Future<bool> removeItemFromCart(String userId, String productId) async {
    try {
      final cart = await getCart(userId);

      if (cart.isEmpty) {
        log('Cart is empty');
        return false;
      }

      // Remove item
      final updatedItems =
          cart.items.where((item) => item.productId != productId).toList();

      if (updatedItems.length == cart.items.length) {
        log('Item not found in cart: $productId');
        return false;
      }

      // If cart becomes empty, clear storeId
      if (updatedItems.isEmpty) {
        await clearCart(userId);
        log('Last item removed, cart cleared');
        return true;
      }

      // Recalculate totals
      final newSubtotal = updatedItems.fold<double>(
        0.0,
        (sum, item) => sum + item.total,
      );
      final newTotalItems = updatedItems.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );

      final updatedCart = cart.copyWith(
        items: updatedItems,
        totalItems: newTotalItems,
        subtotal: newSubtotal,
        total: newSubtotal + cart.deliveryFee - cart.discount,
        updatedAt: DateTime.now(),
      );

      await _cartsCollection.doc(userId).update(updatedCart.toJson());

      log('Item removed from cart: $productId');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error removing item: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error removing item: ${e.toString()}');
      return false;
    }
  }

  /// Clear entire cart
  Future<bool> clearCart(String userId) async {
    try {
      await _cartsCollection.doc(userId).delete();
      log('Cart cleared for user: $userId');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error clearing cart: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error clearing cart: ${e.toString()}');
      return false;
    }
  }

  /// Get cart item count
  Future<int> getCartItemCount(String userId) async {
    try {
      final cart = await getCart(userId);
      return cart.totalItems;
    } catch (e) {
      log('Error getting cart count: ${e.toString()}');
      return 0;
    }
  }

  /// Validate cart (check availability and prices)
  Future<bool> validateCart(String userId) async {
    try {
      final cart = await getCart(userId);

      if (cart.isEmpty) return true;

      bool needsUpdate = false;
      List<CartItemModel> validItems = [];

      // Check each item
      for (var item in cart.items) {
        // Here you would fetch the actual product to check:
        // 1. Is it still available?
        // 2. Has the price changed?
        // 3. Is there enough stock?

        // For now, we'll assume validation passes
        // In production, fetch product and validate
        validItems.add(item);
      }

      if (needsUpdate) {
        // Update cart with valid items
        final newSubtotal = validItems.fold<double>(
          0.0,
          (sum, item) => sum + item.total,
        );
        final newTotalItems = validItems.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        );

        final updatedCart = cart.copyWith(
          items: validItems,
          totalItems: newTotalItems,
          subtotal: newSubtotal,
          total: newSubtotal + cart.deliveryFee - cart.discount,
          updatedAt: DateTime.now(),
        );

        await _cartsCollection.doc(userId).update(updatedCart.toJson());
        log('Cart validated and updated');
      }

      return true;
    } catch (e) {
      log('Error validating cart: ${e.toString()}');
      return false;
    }
  }

  /// Update delivery fee
  Future<bool> updateDeliveryFee(String userId, double deliveryFee) async {
    try {
      final cart = await getCart(userId);

      final updatedCart = cart.copyWith(
        deliveryFee: deliveryFee,
        total: cart.subtotal + deliveryFee - cart.discount,
        updatedAt: DateTime.now(),
      );

      await _cartsCollection.doc(userId).update(updatedCart.toJson());
      log('Delivery fee updated: $deliveryFee');
      return true;
    } catch (e) {
      log('Error updating delivery fee: ${e.toString()}');
      return false;
    }
  }

  /// Apply discount
  Future<bool> applyDiscount(String userId, double discount) async {
    try {
      final cart = await getCart(userId);

      final updatedCart = cart.copyWith(
        discount: discount,
        total: cart.subtotal + cart.deliveryFee - discount,
        updatedAt: DateTime.now(),
      );

      await _cartsCollection.doc(userId).update(updatedCart.toJson());
      log('Discount applied: $discount');
      return true;
    } catch (e) {
      log('Error applying discount: ${e.toString()}');
      return false;
    }
  }
}
