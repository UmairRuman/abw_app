// lib/features/cart/data/collections/carts_collection.dart

import 'dart:developer';
import 'package:abw_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as ref;
import '../models/cart_model.dart';
import '../models/cart_item_model.dart';



class CartWithRemovedInfo {
  final CartModel cart;
  final List<String> removedNames;
  const CartWithRemovedInfo({required this.cart, required this.removedNames});
}

class CartsCollection {
  static final CartsCollection instance = CartsCollection._internal();
  CartsCollection._internal();
  factory CartsCollection() => instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  final doc = await _firestore.collection('carts').doc(userId).get();
  if (!doc.exists) return CartModel.empty(userId);

  final cart = CartModel.fromJson(doc.data()!);
  if (cart.isEmpty) return cart;

  // ✅ Validate items against current product availability
  return await _validateAndCleanCart(userId, cart);
}

// Add this method to CartsCollection class
Future<CartWithRemovedInfo> getCartWithRemovedInfo(String userId) async {
  final doc = await _firestore.collection('carts').doc(userId).get();
  if (!doc.exists) {
    return CartWithRemovedInfo(
      cart: CartModel.empty(userId),
      removedNames: [],
    );
  }

  final cart = CartModel.fromJson(doc.data()!);
  if (cart.isEmpty) {
    return CartWithRemovedInfo(cart: cart, removedNames: []);
  }

  // Validate against product availability
  final productIds = cart.items.map((i) => i.productId).toSet().toList();
  final unavailableIds = <String>{};

  for (int i = 0; i < productIds.length; i += 30) {
    final chunk = productIds.sublist(
      i, (i + 30 > productIds.length) ? productIds.length : i + 30,
    );

    final snapshot = await _firestore
        .collection('products')
        .where(FieldPath.documentId, whereIn: chunk)
        .get();

    // Mark unavailable products
    for (final doc in snapshot.docs) {
      final isAvailable = (doc.data()['isAvailable'] as bool?) ?? true;
      if (!isAvailable) unavailableIds.add(doc.id);
    }

    // Mark hard-deleted products (not returned at all)
    final returnedIds = snapshot.docs.map((d) => d.id).toSet();
    for (final id in chunk) {
      if (!returnedIds.contains(id)) unavailableIds.add(id);
    }
  }

  if (unavailableIds.isEmpty) {
    return CartWithRemovedInfo(cart: cart, removedNames: []);
  }

  // Collect removed item names for toast message
  final removedNames = cart.items
      .where((item) => unavailableIds.contains(item.productId))
      .map((item) => item.productName)
      .toList();

  // Rebuild cart with only valid items
  final validItems = cart.items
      .where((item) => !unavailableIds.contains(item.productId))
      .toList();

  log('🛒 Removed ${removedNames.length} unavailable items: $removedNames');

  final cleanedCart = _rebuildCart(cart, validItems);

  // Persist cleaned cart to Firestore
  if (validItems.isEmpty) {
    await _cartsCollection.doc(userId).delete();
  } else {
    await _cartsCollection.doc(userId).set(cleanedCart.toJson());
  }

  return CartWithRemovedInfo(cart: cleanedCart, removedNames: removedNames);
}

Future<CartModel> _validateAndCleanCart(String userId, CartModel cart) async {
  if (cart.items.isEmpty) return cart;

  // Fetch all product IDs in one batch read — not N reads
  final productIds = cart.items.map((i) => i.productId).toSet().toList();

  // Firestore whereIn supports up to 30 items per query
  final unavailableIds = <String>{};

  for (int i = 0; i < productIds.length; i += 30) {
    final chunk = productIds.sublist(
      i, i + 30 > productIds.length ? productIds.length : i + 30,
    );

    final snapshot = await _firestore
        .collection('products')
        .where(FieldPath.documentId, whereIn: chunk)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final isAvailable = data['isAvailable'] as bool? ?? true;
      final isDeleted = !doc.exists;

      if (!isAvailable || isDeleted) {
        unavailableIds.add(doc.id);
      }
    }

    // Also catch products that don't exist at all (truly deleted)
    final returnedIds = snapshot.docs.map((d) => d.id).toSet();
    for (final id in chunk) {
      if (!returnedIds.contains(id)) {
        unavailableIds.add(id); // Product was hard-deleted
      }
    }
  }

  if (unavailableIds.isEmpty) return cart; // Nothing to clean

  // Remove unavailable items from cart in Firestore
  final validItems = cart.items
      .where((item) => !unavailableIds.contains(item.productId))
      .toList();

  final removedItems = cart.items
      .where((item) => unavailableIds.contains(item.productId))
      .toList();

  log('🛒 Cart cleanup: removed ${removedItems.length} unavailable items: '
      '${removedItems.map((i) => i.productName).join(', ')}');

  // Persist cleaned cart back to Firestore
  final cleanedCart = _rebuildCart(cart, validItems);
  await _firestore
      .collection('carts')
      .doc(userId)
      .set(cleanedCart.toJson());

  return cleanedCart;
}

CartModel _rebuildCart(CartModel original, List<CartItemModel> validItems) {
  if (validItems.isEmpty) return CartModel.empty(original.userId);

  final subtotal = validItems.fold<double>(
    0, (sum, item) => sum + item.total,
  );
  final totalItems = validItems.fold<int>(
    0, (sum, item) => sum + item.quantity,
  );

  return original.copyWith(
    items: validItems,
    subtotal: subtotal,
    total: subtotal + original.deliveryFee - original.discount,
    totalItems: totalItems,
    updatedAt: DateTime.now(),
  );
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
