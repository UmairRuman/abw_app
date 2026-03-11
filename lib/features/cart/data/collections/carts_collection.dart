// lib/features/cart/data/collections/carts_collection.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';
import '../models/cart_item_model.dart';

class CartsCollection {
  static final CartsCollection instance = CartsCollection._internal();
  CartsCollection._internal();
  factory CartsCollection() => instance;

  static final _cartsCollection = FirebaseFirestore.instance.collection(
    'carts',
  );

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Derive the cart item key from a raw Firestore map.
  /// Falls back to productId so old cart docs (without cartItemKey) still work.
  String _keyOf(Map<String, dynamic> item) =>
      item['cartItemKey'] as String? ?? item['productId'] as String;

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<CartModel> getCart(String userId) async {
    try {
      final snapshot = await _cartsCollection.doc(userId).get();
      if (snapshot.exists && snapshot.data() != null) {
        return CartModel.fromJson(snapshot.data()!);
      }
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

  // ── Add ───────────────────────────────────────────────────────────────────

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

        // Different store → caller shows replace-cart dialog
        if (currentStoreId != null &&
            currentStoreId.isNotEmpty &&
            currentStoreId != item.storeId) {
          return false;
        }

        final rawItems = List<Map<String, dynamic>>.from(
          cartData['items'] as List? ?? [],
        );

        // ✅ FIX: match on cartItemKey, not productId.
        // This makes Small Pizza and Large Pizza separate entries.
        final existingIndex = rawItems.indexWhere(
          (i) => _keyOf(i) == item.cartItemKey,
        );

        if (existingIndex >= 0) {
          // Same product + same variant → just increase quantity
          final newQty =
              (rawItems[existingIndex]['quantity'] as int) + item.quantity;
          final unitPrice =
              (rawItems[existingIndex]['discountedPrice'] as num).toDouble();
          rawItems[existingIndex]['quantity'] = newQty;
          rawItems[existingIndex]['total'] = unitPrice * newQty;
        } else {
          // Different variant (or brand-new product) → add as separate row
          final newItem = item.toJson();
          newItem['total'] = item.discountedPrice * item.quantity;
          rawItems.add(newItem);
        }

        await _recalculateAndUpdate(userId, cartData, rawItems);
        return true;
      } else {
        // ── Create new cart ────────────────────────────────────────────────
        final itemTotal = item.discountedPrice * item.quantity;
        await _cartsCollection.doc(userId).set({
          'userId': userId,
          'storeId': item.storeId,
          'storeName': item.storeName,
          'items': [
            {...item.toJson(), 'total': itemTotal},
          ],
          'subtotal': itemTotal,
          'deliveryFee': deliveryFee,
          'discount': 0.0,
          'total': itemTotal + deliveryFee,
          'totalItems': item.quantity,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        log('✅ New cart created - total: ${itemTotal + deliveryFee}');
        return true;
      }
    } catch (e) {
      log('❌ Error adding item to cart: $e');
      rethrow;
    }
  }

  // ── Quantity ──────────────────────────────────────────────────────────────

  /// Update quantity by cartItemKey (supports variant-specific items).
  Future<bool> updateItemQuantity(
    String userId,
    String cartItemKey,
    int newQuantity,
  ) async {
    try {
      final cart = await getCart(userId);
      if (cart.isEmpty) return false;

      // ✅ FIX: find by cartItemKey
      final itemIndex = cart.items.indexWhere(
        (item) => item.cartItemKey == cartItemKey,
      );
      if (itemIndex == -1) {
        log('Item not found in cart: $cartItemKey');
        return false;
      }
      if (newQuantity < 1) return false;

      final item = cart.items[itemIndex];
      if (newQuantity > item.maxQuantity) {
        throw Exception('Maximum quantity is ${item.maxQuantity}');
      }

      final List<CartItemModel> updatedItems = List.from(cart.items);
      updatedItems[itemIndex] = item.copyWith(
        quantity: newQuantity,
        total: item.discountedPrice * newQuantity,
      );

      final newSubtotal = updatedItems.fold<double>(0.0, (s, i) => s + i.total);
      final newTotalItems = updatedItems.fold<int>(0, (s, i) => s + i.quantity);

      final updatedCart = cart.copyWith(
        items: updatedItems,
        totalItems: newTotalItems,
        subtotal: newSubtotal,
        total: newSubtotal + cart.deliveryFee - cart.discount,
        updatedAt: DateTime.now(),
      );

      await _cartsCollection.doc(userId).update(updatedCart.toJson());
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error updating quantity: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error updating quantity: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> incrementQuantity(String userId, String cartItemKey) async {
    try {
      final cartDoc = await _cartsCollection.doc(userId).get();
      if (!cartDoc.exists) return;

      final cartData = cartDoc.data()!;
      final rawItems = List<Map<String, dynamic>>.from(
        cartData['items'] as List? ?? [],
      );

      // ✅ FIX: match on cartItemKey
      final index = rawItems.indexWhere((i) => _keyOf(i) == cartItemKey);
      if (index < 0) return;

      rawItems[index]['quantity'] = (rawItems[index]['quantity'] as int) + 1;
      rawItems[index]['total'] =
          (rawItems[index]['discountedPrice'] as num).toDouble() *
          (rawItems[index]['quantity'] as num);

      await _recalculateAndUpdate(userId, cartData, rawItems);
    } catch (e) {
      log('Error incrementing: $e');
      rethrow;
    }
  }

  Future<void> decrementQuantity(String userId, String cartItemKey) async {
    try {
      final cartDoc = await _cartsCollection.doc(userId).get();
      if (!cartDoc.exists) return;

      final cartData = cartDoc.data()!;
      final rawItems = List<Map<String, dynamic>>.from(
        cartData['items'] as List? ?? [],
      );

      // ✅ FIX: match on cartItemKey
      final index = rawItems.indexWhere((i) => _keyOf(i) == cartItemKey);
      if (index < 0) return;

      final currentQty = rawItems[index]['quantity'] as int;
      if (currentQty <= 1) {
        rawItems.removeAt(index);
      } else {
        rawItems[index]['quantity'] = currentQty - 1;
        rawItems[index]['total'] =
            (rawItems[index]['discountedPrice'] as num).toDouble() *
            (rawItems[index]['quantity'] as num);
      }

      await _recalculateAndUpdate(userId, cartData, rawItems);
    } catch (e) {
      log('Error decrementing: $e');
      rethrow;
    }
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  /// Remove a single cart entry by cartItemKey.
  Future<bool> removeItemFromCart(String userId, String cartItemKey) async {
    try {
      final cart = await getCart(userId);
      if (cart.isEmpty) return false;

      // ✅ FIX: filter by cartItemKey so only that variant row is removed
      final updatedItems =
          cart.items.where((item) => item.cartItemKey != cartItemKey).toList();

      if (updatedItems.length == cart.items.length) {
        log('Item not found in cart: $cartItemKey');
        return false;
      }

      if (updatedItems.isEmpty) {
        await clearCart(userId);
        return true;
      }

      final newSubtotal = updatedItems.fold<double>(0.0, (s, i) => s + i.total);
      final newTotalItems = updatedItems.fold<int>(0, (s, i) => s + i.quantity);

      final updatedCart = cart.copyWith(
        items: updatedItems,
        totalItems: newTotalItems,
        subtotal: newSubtotal,
        total: newSubtotal + cart.deliveryFee - cart.discount,
        updatedAt: DateTime.now(),
      );

      await _cartsCollection.doc(userId).update(updatedCart.toJson());
      log('Item removed from cart: $cartItemKey');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error removing item: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error removing item: ${e.toString()}');
      return false;
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

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

  // ── Misc ──────────────────────────────────────────────────────────────────

  Future<int> getCartItemCount(String userId) async {
    try {
      final cart = await getCart(userId);
      return cart.totalItems;
    } catch (e) {
      log('Error getting cart count: ${e.toString()}');
      return 0;
    }
  }

  Future<bool> validateCart(String userId) async {
    try {
      // Placeholder — fetch products and validate availability/prices here.
      return true;
    } catch (e) {
      log('Error validating cart: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateDeliveryFee(String userId, double deliveryFee) async {
    try {
      final cart = await getCart(userId);
      final updatedCart = cart.copyWith(
        deliveryFee: deliveryFee,
        total: cart.subtotal + deliveryFee - cart.discount,
        updatedAt: DateTime.now(),
      );
      await _cartsCollection.doc(userId).update(updatedCart.toJson());
      return true;
    } catch (e) {
      log('Error updating delivery fee: ${e.toString()}');
      return false;
    }
  }

  Future<bool> applyDiscount(String userId, double discount) async {
    try {
      final cart = await getCart(userId);
      final updatedCart = cart.copyWith(
        discount: discount,
        total: cart.subtotal + cart.deliveryFee - discount,
        updatedAt: DateTime.now(),
      );
      await _cartsCollection.doc(userId).update(updatedCart.toJson());
      return true;
    } catch (e) {
      log('Error applying discount: ${e.toString()}');
      return false;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

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

    await _cartsCollection.doc(userId).update({
      'items': items,
      'subtotal': subtotal,
      'deliveryFee': items.isEmpty ? 0.0 : deliveryFee,
      'total': subtotal + deliveryFee,
      'totalItems': totalItems,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    log(
      '✅ Cart recalculated — subtotal: $subtotal, fee: $deliveryFee, '
      'total: ${subtotal + deliveryFee}, items: $totalItems',
    );
  }
}
