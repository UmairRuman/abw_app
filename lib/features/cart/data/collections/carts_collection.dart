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

  Future<bool> addItemToCart(
    String userId,
    CartItemModel item, {
    double deliveryFee = 50.0,
  }) async {
    try {
      final cartDoc = await _cartsCollection.doc(userId).get();

      if (cartDoc.exists) {
        final cartData = cartDoc.data()!;
        final currentStoreId = cartData['storeId'] as String?;

        // ✅ CHECK DIFFERENT STORE
        if (currentStoreId != null &&
            currentStoreId.isNotEmpty &&
            currentStoreId != item.storeId) {
          return false;
        }

        // ✅ GET EXISTING ITEMS
        final rawItems = List<Map<String, dynamic>>.from(
          cartData['items'] as List? ?? [],
        );

        // ✅ CHECK IF ITEM ALREADY EXISTS
        final existingIndex = rawItems.indexWhere(
          (i) => i['productId'] == item.productId,
        );

        if (existingIndex >= 0) {
          // ✅ UPDATE EXISTING ITEM
          final newQty =
              (rawItems[existingIndex]['quantity'] as int) + item.quantity;
          final unitPrice =
              (rawItems[existingIndex]['discountedPrice'] as num).toDouble();
          rawItems[existingIndex]['quantity'] = newQty;
          rawItems[existingIndex]['total'] =
              unitPrice * newQty; // ✅ RECALCULATE
        } else {
          // ✅ ADD NEW ITEM WITH CORRECT TOTAL
          final newItem = item.toJson();
          newItem['total'] =
              item.discountedPrice * item.quantity; // ✅ ENSURE CORRECT
          rawItems.add(newItem);
        }

        // ✅ RECALCULATE SUBTOTAL FROM ALL ITEMS
        double subtotal = 0;
        int totalItems = 0;
        for (final i in rawItems) {
          final qty = (i['quantity'] as num).toInt();
          final price = (i['discountedPrice'] as num).toDouble();
          final itemTotal = price * qty; // ✅ ALWAYS RECALCULATE
          i['total'] = itemTotal; // ✅ SYNC ITEM TOTAL
          subtotal += itemTotal;
          totalItems += qty;
        }

        // ✅ GET CURRENT DELIVERY FEE
        final currentDeliveryFee =
            (cartData['deliveryFee'] as num?)?.toDouble() ?? deliveryFee;

        await _cartsCollection.doc(userId).update({
          'items': rawItems,
          'storeId': item.storeId,
          'storeName': item.storeName,
          'subtotal': subtotal,
          'deliveryFee': currentDeliveryFee,
          'total': subtotal + currentDeliveryFee,
          'totalItems': totalItems,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        log(
          '✅ Cart updated - subtotal: $subtotal, deliveryFee: $currentDeliveryFee, total: ${subtotal + currentDeliveryFee}',
        );
        return true;
      } else {
        // ✅ CREATE NEW CART
        final itemTotal = item.discountedPrice * item.quantity;
        final subtotal = itemTotal;
        final total = subtotal + deliveryFee;

        final cartData = {
          'userId': userId,
          'storeId': item.storeId,
          'storeName': item.storeName,
          'items': [
            {
              ...item.toJson(),
              'total': itemTotal, // ✅ ENSURE CORRECT TOTAL
            },
          ],
          'subtotal': subtotal,
          'deliveryFee': deliveryFee, // ✅ FROM STORE
          'discount': 0.0,
          'total': total,
          'totalItems': item.quantity,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _cartsCollection.doc(userId).set(cartData);

        log(
          '✅ New cart created - subtotal: $subtotal, deliveryFee: $deliveryFee, total: $total',
        );
        return true;
      }
    } catch (e) {
      log('❌ Error adding item to cart: $e');
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
      final List<CartItemModel> updatedItems = List.from(cart.items);
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

  Future<void> incrementQuantity(String userId, String productId) async {
    try {
      final cartDoc = await _cartsCollection.doc(userId).get();
      if (!cartDoc.exists) return;

      final cartData = cartDoc.data()!;
      final rawItems = List<Map<String, dynamic>>.from(
        cartData['items'] as List? ?? [],
      );

      final index = rawItems.indexWhere((i) => i['productId'] == productId);
      if (index < 0) return;

      // ✅ INCREMENT AND RECALCULATE
      rawItems[index]['quantity'] = (rawItems[index]['quantity'] as int) + 1;
      rawItems[index]['total'] =
          (rawItems[index]['discountedPrice'] as num).toDouble() *
          (rawItems[index]['quantity'] as num);

      // ✅ RECALCULATE ALL TOTALS
      _recalculateAndUpdate(userId, cartData, rawItems);
    } catch (e) {
      log('Error incrementing: $e');
      rethrow;
    }
  }

  // REPLACE decrementQuantity:
  Future<void> decrementQuantity(String userId, String productId) async {
    try {
      final cartDoc = await _cartsCollection.doc(userId).get();
      if (!cartDoc.exists) return;

      final cartData = cartDoc.data()!;
      final rawItems = List<Map<String, dynamic>>.from(
        cartData['items'] as List? ?? [],
      );

      final index = rawItems.indexWhere((i) => i['productId'] == productId);
      if (index < 0) return;

      final currentQty = rawItems[index]['quantity'] as int;

      if (currentQty <= 1) {
        // Remove item
        rawItems.removeAt(index);
      } else {
        // ✅ DECREMENT AND RECALCULATE
        rawItems[index]['quantity'] = currentQty - 1;
        rawItems[index]['total'] =
            (rawItems[index]['discountedPrice'] as num).toDouble() *
            (rawItems[index]['quantity'] as num);
      }

      _recalculateAndUpdate(userId, cartData, rawItems);
    } catch (e) {
      log('Error decrementing: $e');
      rethrow;
    }
  }

  // ✅ ADD THIS HELPER METHOD:
  Future<void> _recalculateAndUpdate(
    String userId,
    Map<String, dynamic> cartData,
    List<Map<String, dynamic>> items,
  ) async {
    double subtotal = 0;
    int totalItems = 0;

    for (final item in items) {
      final qty = (item['quantity'] as num).toInt();
      final price = (item['discountedPrice'] as num).toDouble();
      final itemTotal = price * qty;
      item['total'] = itemTotal;
      subtotal += itemTotal;
      totalItems += qty;
    }

    final deliveryFee =
        items.isEmpty
            ? 0.0
            : (cartData['deliveryFee'] as num?)?.toDouble() ?? 50.0;

    final total = subtotal + deliveryFee;

    await _cartsCollection.doc(userId).update({
      'items': items,
      'subtotal': subtotal,
      'deliveryFee': items.isEmpty ? 0.0 : deliveryFee,
      'total': total,
      'totalItems': totalItems,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    log(
      '✅ Recalculated - subtotal: $subtotal, fee: $deliveryFee, total: $total, items: $totalItems',
    );
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

      final bool needsUpdate = false;
      final List<CartItemModel> validItems = [];

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
