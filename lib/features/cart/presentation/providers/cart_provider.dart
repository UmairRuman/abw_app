// lib/features/cart/presentation/providers/cart_provider.dart

import 'dart:developer';
import 'package:abw_app/features/products/data/models/product_model.dart';
import 'package:abw_app/features/products/domain/entities/product_variant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/carts_collection.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/cart_item_model.dart';

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<CartState> {
  late final CartsCollection _collection;

  @override
  CartState build() {
    _collection = CartsCollection();
    return CartInitial();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadCart(String userId) async {
    state = CartLoading();
    try {
      final cart = await _collection.getCart(userId);
      state = CartLoaded(cart: cart);
    } catch (e) {
      state = CartError(error: e.toString());
      log('Error in loadCart: ${e.toString()}');
    }
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<bool> addToCart(
    String userId,
    ProductModel product,
    int quantity, {
    ProductVariant? selectedVariant,
    List<ProductAddon> selectedAddons = const [],
    String? specialInstructions,
  }) async {
    try {
      // ── Fetch delivery fee ────────────────────────────────────────────────
      double deliveryFee = 50.0;
      try {
        final storeDoc =
            await FirebaseFirestore.instance
                .collection('stores')
                .doc(product.storeId)
                .get();
        if (storeDoc.exists) {
          deliveryFee =
              (storeDoc.data()!['deliveryFee'] as num?)?.toDouble() ?? 50.0;
        }
      } catch (e) {
        log('⚠️ Could not fetch delivery fee, using default: $e');
      }

      // ── Effective price ───────────────────────────────────────────────────
      // Variant price IS the full item price (not an extra on top).
      final double itemBasePrice =
          selectedVariant != null
              ? selectedVariant.price
              : product.discountedPrice;

      final double addonsExtra = selectedAddons.fold(
        0.0,
        (sum, addon) => sum + addon.price,
      );
      final double effectivePrice = itemBasePrice + addonsExtra;

      log(
        '💰 Price → base: $itemBasePrice + addons: $addonsExtra = $effectivePrice',
      );

      // ── Build cart item ───────────────────────────────────────────────────
      final cartItem = CartItemModel(
        productId: product.id,
        productName: product.name,
        productImage: product.thumbnail,
        storeId: product.storeId,
        storeName: product.storeName,
        price: product.price, // original list price (display only)
        quantity: quantity,
        discountedPrice: effectivePrice, // effective price per unit
        total: effectivePrice * quantity,
        isAvailable: product.isAvailable,
        maxQuantity: product.maxOrderQuantity,
        unit: product.unit,
        selectedVariant: selectedVariant,
        selectedAddons: selectedAddons,
        specialInstructions: specialInstructions,
      );

      // ── Persist ───────────────────────────────────────────────────────────
      final success = await _collection.addItemToCart(
        userId,
        cartItem,
        deliveryFee: deliveryFee,
      );

      if (!success) return false; // Different store — caller handles dialog

      await loadCart(userId);
      return true;
    } catch (e) {
      state = CartError(error: e.toString());
      log('Error adding to cart: ${e.toString()}');
      return false;
    }
  }

  Future<bool> clearAndAddToCart(
    String userId,
    ProductModel product,
    int quantity, {
    ProductVariant? selectedVariant,
    List<ProductAddon> selectedAddons = const [],
    String? specialInstructions,
  }) async {
    try {
      await clearCart(userId);
      return await addToCart(
        userId,
        product,
        quantity,
        selectedVariant: selectedVariant,
        selectedAddons: selectedAddons,
        specialInstructions: specialInstructions,
      );
    } catch (e) {
      state = CartError(error: e.toString());
      log('Error clearing and adding to cart: ${e.toString()}');
      return false;
    }
  }

  // ── Quantity ──────────────────────────────────────────────────────────────

  /// ✅ FIX: all quantity methods now take cartItemKey, not productId.
  Future<bool> updateQuantity(
    String userId,
    String cartItemKey,
    int quantity,
  ) async {
    try {
      final success = await _collection.updateItemQuantity(
        userId,
        cartItemKey,
        quantity,
      );
      if (success) await loadCart(userId);
      return success;
    } catch (e) {
      state = CartError(error: e.toString());
      log('Error in updateQuantity: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> incrementQuantity(String userId, String cartItemKey) async {
    try {
      if (state is! CartLoaded) await loadCart(userId);

      if (state is CartLoaded) {
        final cart = (state as CartLoaded).cart;
        // ✅ FIX: look up by cartItemKey
        final item = cart.items.firstWhere(
          (item) => item.cartItemKey == cartItemKey,
        );
        return await updateQuantity(userId, cartItemKey, item.quantity + 1);
      }
      return false;
    } catch (e) {
      log('Error in incrementQuantity: ${e.toString()}');
      return false;
    }
  }

  Future<bool> decrementQuantity(String userId, String cartItemKey) async {
    try {
      if (state is! CartLoaded) await loadCart(userId);

      if (state is CartLoaded) {
        final cart = (state as CartLoaded).cart;
        // ✅ FIX: look up by cartItemKey
        final item = cart.items.firstWhere(
          (item) => item.cartItemKey == cartItemKey,
        );

        if (item.quantity - 1 < 1) {
          return await removeItem(userId, cartItemKey);
        }
        return await updateQuantity(userId, cartItemKey, item.quantity - 1);
      }
      return false;
    } catch (e) {
      log('Error in decrementQuantity: ${e.toString()}');
      return false;
    }
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  Future<bool> removeItem(String userId, String cartItemKey) async {
    try {
      final success = await _collection.removeItemFromCart(userId, cartItemKey);
      if (success) await loadCart(userId);
      return success;
    } catch (e) {
      state = CartError(error: e.toString());
      log('Error in removeItem: ${e.toString()}');
      return false;
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  Future<bool> clearCart(String userId) async {
    try {
      final success = await _collection.clearCart(userId);
      if (success) state = CartLoaded(cart: CartModel.empty(userId));
      return success;
    } catch (e) {
      state = CartError(error: e.toString());
      log('Error in clearCart: ${e.toString()}');
      return false;
    }
  }

  // ── Misc ──────────────────────────────────────────────────────────────────

  Future<bool> validateCart(String userId) async {
    try {
      final success = await _collection.validateCart(userId);
      if (success) await loadCart(userId);
      return success;
    } catch (e) {
      log('Error in validateCart: ${e.toString()}');
      return false;
    }
  }

  Future<int> getCartCount(String userId) async {
    try {
      return await _collection.getCartItemCount(userId);
    } catch (e) {
      log('Error in getCartCount: ${e.toString()}');
      return 0;
    }
  }

  Future<bool> updateDeliveryFee(String userId, double fee) async {
    try {
      final success = await _collection.updateDeliveryFee(userId, fee);
      if (success) await loadCart(userId);
      return success;
    } catch (e) {
      log('Error in updateDeliveryFee: ${e.toString()}');
      return false;
    }
  }

  Future<bool> applyDiscount(String userId, double discount) async {
    try {
      final success = await _collection.applyDiscount(userId, discount);
      if (success) await loadCart(userId);
      return success;
    } catch (e) {
      log('Error in applyDiscount: ${e.toString()}');
      return false;
    }
  }

  // ── UI Helpers ────────────────────────────────────────────────────────────

  double getSubtotal() =>
      state is CartLoaded ? (state as CartLoaded).cart.subtotal : 0.0;

  double getTotal() =>
      state is CartLoaded ? (state as CartLoaded).cart.total : 0.0;

  int getItemCount() =>
      state is CartLoaded ? (state as CartLoaded).cart.totalItems : 0;

  bool isEmpty() =>
      state is CartLoaded ? (state as CartLoaded).cart.isEmpty : true;

  bool showCartBadge() => getItemCount() > 0;

  String getCartBadgeCount() {
    final count = getItemCount();
    return count > 9 ? '9+' : count.toString();
  }
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class CartState {}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final CartModel cart;
  CartLoaded({required this.cart});
}

class CartError extends CartState {
  final String error;
  CartError({required this.error});
}
