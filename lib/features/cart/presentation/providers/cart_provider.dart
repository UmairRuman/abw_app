// lib/features/cart/presentation/providers/cart_provider.dart

import 'dart:developer';
import 'package:abw_app/features/products/data/models/product_model.dart';
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
  Future<void> addToCart(
  String userId,
  ProductModel product,  // ✅ Accept ProductModel
  int quantity,
) async {
  try {
    // Convert ProductModel to CartItemModel
    final cartItem = CartItemModel(
      productId: product.id,
      productName: product.name,
      productImage: product.thumbnail,
      storeId: product.storeId,
      storeName: product.storeName,
      price: product.price,
      quantity: quantity,
      discountedPrice: product.discountedPrice,
      total: product.discountedPrice * quantity,
      isAvailable: product.isAvailable,
      maxQuantity: product.maxOrderQuantity,
      unit: product.unit,
    );

    // Add to cart using the collection
    final success = await _collection.addItemToCart(userId, cartItem);

    if (success) {
      // Reload cart to get updated state
      await loadCart(userId);
    }
  } catch (e) {
    state = CartError(error: e.toString());
    log('Error adding to cart: ${e.toString()}');
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