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

  /// Load user's cart
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

  /// Add item to cart
  Future<bool> addToCart(
    String userId,
    ProductModel product,
    int quantity, {
    ProductVariant? selectedVariant,
    List<ProductAddon> selectedAddons = const [],
    String? specialInstructions,
  }) async {
    try {
      // ── STEP 1: Fetch delivery fee ────────────────────────────────────────
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
          log('✅ Delivery fee from store: $deliveryFee');
        }
      } catch (e) {
        log('⚠️ Could not fetch delivery fee, using default: $e');
      }

      // ── STEP 2: Calculate effective price ─────────────────────────────────
      //
      // Rule:
      //   • If the product has a selected variant  → variant.price IS the price
      //     (it is a standalone size price, e.g. Small=500, Medium=750, Large=1200)
      //   • If no variant selected                 → use product.discountedPrice
      //   • Addons are ALWAYS additional on top of whichever price applies
      //
      final double itemBasePrice =
          selectedVariant != null
              ? selectedVariant
                  .price // ← variant price = full item price
              : product.discountedPrice; // ← fallback for plain products

      final double addonsExtra = selectedAddons.fold(
        0.0,
        (sum, addon) => sum + addon.price,
      );
      final double effectivePrice = itemBasePrice + addonsExtra;

      log(
        '💰 Price → variant/base: $itemBasePrice + addons: $addonsExtra = $effectivePrice',
      );

      // ── STEP 3: Build cart item ───────────────────────────────────────────
      // IMPORTANT: store effectivePrice as discountedPrice so that
      // CartModel.fromJson (which computes subtotal = Σ item.discountedPrice * qty)
      // always reflects the correct price shown to the customer.
      final cartItem = CartItemModel(
        productId: product.id,
        productName: product.name,
        productImage: product.thumbnail,
        storeId: product.storeId,
        storeName: product.storeName,
        price: product.price, // original list price (for reference)
        quantity: quantity,
        discountedPrice: effectivePrice, // ✅ FIXED: was product.discountedPrice
        total: effectivePrice * quantity,
        isAvailable: product.isAvailable,
        maxQuantity: product.maxOrderQuantity,
        unit: product.unit,
        selectedVariant: selectedVariant,
        selectedAddons: selectedAddons,
        specialInstructions: specialInstructions,
      );

      // ── STEP 4: Persist ───────────────────────────────────────────────────
      final success = await _collection.addItemToCart(
        userId,
        cartItem,
        deliveryFee: deliveryFee,
      );

      if (!success) {
        // Different store — caller handles the replace-cart dialog
        return false;
      }

      // ── STEP 5: Reload ────────────────────────────────────────────────────
      await loadCart(userId);
      return true;
    } catch (e) {
      state = CartError(error: e.toString());
      log('Error adding to cart: ${e.toString()}');
      return false;
    }
  }

  /// Clear cart and add a new item (used when switching stores).
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

  /// Update item quantity
  Future<bool> updateQuantity(
    String userId,
    String productId,
    int quantity,
  ) async {
    try {
      final success = await _collection.updateItemQuantity(
        userId,
        productId,
        quantity,
      );

      if (success) {
        await loadCart(userId);
        return true;
      }

      return false;
    } catch (e) {
      state = CartError(error: e.toString());
      log('Error in updateQuantity: ${e.toString()}');
      rethrow;
    }
  }

  /// Increment quantity
  Future<bool> incrementQuantity(String userId, String productId) async {
    try {
      // Get current cart
      if (state is! CartLoaded) {
        await loadCart(userId);
      }

      if (state is CartLoaded) {
        final cart = (state as CartLoaded).cart;
        final item = cart.items.firstWhere(
          (item) => item.productId == productId,
        );

        return await updateQuantity(userId, productId, item.quantity + 1);
      }

      return false;
    } catch (e) {
      log('Error in incrementQuantity: ${e.toString()}');
      return false;
    }
  }

  /// Decrement quantity
  Future<bool> decrementQuantity(String userId, String productId) async {
    try {
      if (state is! CartLoaded) {
        await loadCart(userId);
      }

      if (state is CartLoaded) {
        final cart = (state as CartLoaded).cart;
        final item = cart.items.firstWhere(
          (item) => item.productId == productId,
        );

        final newQuantity = item.quantity - 1;

        if (newQuantity < 1) {
          // Remove item if quantity becomes 0
          return await removeItem(userId, productId);
        }

        return await updateQuantity(userId, productId, newQuantity);
      }

      return false;
    } catch (e) {
      log('Error in decrementQuantity: ${e.toString()}');
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeItem(String userId, String productId) async {
    try {
      final success = await _collection.removeItemFromCart(userId, productId);

      if (success) {
        await loadCart(userId);
        return true;
      }

      return false;
    } catch (e) {
      state = CartError(error: e.toString());
      log('Error in removeItem: ${e.toString()}');
      return false;
    }
  }

  /// Clear entire cart
  Future<bool> clearCart(String userId) async {
    try {
      final success = await _collection.clearCart(userId);

      if (success) {
        state = CartLoaded(cart: CartModel.empty(userId));
        return true;
      }

      return false;
    } catch (e) {
      state = CartError(error: e.toString());
      log('Error in clearCart: ${e.toString()}');
      return false;
    }
  }

  /// Validate cart
  Future<bool> validateCart(String userId) async {
    try {
      final success = await _collection.validateCart(userId);

      if (success) {
        await loadCart(userId);
        return true;
      }

      return false;
    } catch (e) {
      log('Error in validateCart: ${e.toString()}');
      return false;
    }
  }

  /// Get cart item count
  Future<int> getCartCount(String userId) async {
    try {
      return await _collection.getCartItemCount(userId);
    } catch (e) {
      log('Error in getCartCount: ${e.toString()}');
      return 0;
    }
  }

  /// Update delivery fee
  Future<bool> updateDeliveryFee(String userId, double fee) async {
    try {
      final success = await _collection.updateDeliveryFee(userId, fee);

      if (success) {
        await loadCart(userId);
        return true;
      }

      return false;
    } catch (e) {
      log('Error in updateDeliveryFee: ${e.toString()}');
      return false;
    }
  }

  /// Apply discount
  Future<bool> applyDiscount(String userId, double discount) async {
    try {
      final success = await _collection.applyDiscount(userId, discount);

      if (success) {
        await loadCart(userId);
        return true;
      }

      return false;
    } catch (e) {
      log('Error in applyDiscount: ${e.toString()}');
      return false;
    }
  }

  // UI Helper methods
  double getSubtotal() {
    if (state is CartLoaded) {
      return (state as CartLoaded).cart.subtotal;
    }
    return 0.0;
  }

  double getTotal() {
    if (state is CartLoaded) {
      return (state as CartLoaded).cart.total;
    }
    return 0.0;
  }

  int getItemCount() {
    if (state is CartLoaded) {
      return (state as CartLoaded).cart.totalItems;
    }
    return 0;
  }

  bool isEmpty() {
    if (state is CartLoaded) {
      return (state as CartLoaded).cart.isEmpty;
    }
    return true;
  }

  bool showCartBadge() {
    return getItemCount() > 0;
  }

  String getCartBadgeCount() {
    final count = getItemCount();
    if (count > 9) return '9+';
    return count.toString();
  }
}

// States
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
