// lib/features/products/presentation/providers/products_provider.dart

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/products_collection.dart';
import '../../data/models/product_model.dart';

final productsProvider = NotifierProvider<ProductsNotifier, ProductsState>(
  ProductsNotifier.new,
);

class ProductsNotifier extends Notifier<ProductsState> {
  late final ProductsCollection _collection;

  @override
  ProductsState build() {
    _collection = ProductsCollection();
    return ProductsInitial();
  }

  /// Get all products
  Future<void> getAllProducts() async {
    state = ProductsLoading();
    
    try {
      final products = await _collection.getAllProducts();
      state = ProductsLoaded(products: products);
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in getAllProducts: ${e.toString()}');
    }
  }

  /// Get products by store (for store detail page)
  Future<void> getProductsByStore(String storeId) async {
    state = ProductsLoading();
    
    try {
      final products = await _collection.getProductsByStore(storeId);
      state = ProductsLoaded(products: products);
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in getProductsByStore: ${e.toString()}');
    }
  }

  /// Get products by category
  Future<void> getProductsByCategory(String categoryId) async {
    state = ProductsLoading();
    
    try {
      final products = await _collection.getProductsByCategory(categoryId);
      state = ProductsLoaded(products: products);
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in getProductsByCategory: ${e.toString()}');
    }
  }

  /// Get featured products (for home screen)
  Future<void> getFeaturedProducts() async {
    state = ProductsLoading();
    
    try {
      final products = await _collection.getFeaturedProducts();
      state = ProductsLoaded(products: products);
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in getFeaturedProducts: ${e.toString()}');
    }
  }

  /// Get popular products
  Future<void> getPopularProducts() async {
    state = ProductsLoading();
    
    try {
      final products = await _collection.getPopularProducts();
      state = ProductsLoaded(products: products);
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in getPopularProducts: ${e.toString()}');
    }
  }

  /// Get single product
  Future<void> getProduct(String productId) async {
    state = ProductsLoading();
    
    try {
      final product = await _collection.getProduct(productId);
      
      if (product != null) {
        state = ProductSingleLoaded(product: product);
      } else {
        state = ProductsError(error: 'Product not found');
      }
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in getProduct: ${e.toString()}');
    }
  }

  /// Add product (HYBRID - writes to both locations)
  Future<bool> addProduct(ProductModel product) async {
    try {
      final success = await _collection.addProduct(product);
      
      if (success) {
        await getAllProducts();
        return true;
      }
      
      return false;
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in addProduct: ${e.toString()}');
      return false;
    }
  }

  /// Update product (HYBRID - updates both locations)
  Future<bool> updateProduct(ProductModel product) async {
    try {
      final success = await _collection.updateProduct(product);
      
      if (success) {
        await getAllProducts();
        return true;
      }
      
      return false;
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in updateProduct: ${e.toString()}');
      return false;
    }
  }

  /// Delete product (HYBRID - deletes from both locations)
  Future<bool> deleteProduct(String productId, String storeId) async {
    try {
      final success = await _collection.deleteProduct(productId, storeId);
      
      if (success) {
        await getAllProducts();
        return true;
      }
      
      return false;
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in deleteProduct: ${e.toString()}');
      return false;
    }
  }

  /// Search products (global)
  Future<void> searchProducts(String query) async {
    state = ProductsLoading();
    
    try {
      final products = await _collection.searchProducts(query);
      state = ProductsLoaded(products: products);
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in searchProducts: ${e.toString()}');
    }
  }

  /// Search products in store
  Future<void> searchInStore(String storeId, String query) async {
    state = ProductsLoading();
    
    try {
      final products = await _collection.searchProductsInStore(storeId, query);
      state = ProductsLoaded(products: products);
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in searchInStore: ${e.toString()}');
    }
  }

  /// Filter by price range
  Future<void> filterByPrice(double min, double max) async {
    state = ProductsLoading();
    
    try {
      final products = await _collection.getProductsByPriceRange(min, max);
      state = ProductsLoaded(products: products);
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in filterByPrice: ${e.toString()}');
    }
  }

  /// Update stock
  Future<bool> updateStock(
    String productId,
    String storeId,
    int quantity,
  ) async {
    try {
      final success = await _collection.updateProductStock(
        productId,
        storeId,
        quantity,
      );
      
      if (success) {
        await getAllProducts();
        return true;
      }
      
      return false;
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in updateStock: ${e.toString()}');
      return false;
    }
  }

  /// Toggle availability
  Future<bool> toggleAvailability(
    String productId,
    String storeId,
    bool isAvailable,
  ) async {
    try {
      final success = await _collection.toggleProductAvailability(
        productId,
        storeId,
        isAvailable,
      );
      
      if (success) {
        await getAllProducts();
        return true;
      }
      
      return false;
    } catch (e) {
      state = ProductsError(error: e.toString());
      log('Error in toggleAvailability: ${e.toString()}');
      return false;
    }
  }
}

// States
abstract class ProductsState {}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<ProductModel> products;
  
  ProductsLoaded({required this.products});
}

class ProductSingleLoaded extends ProductsState {
  final ProductModel product;
  
  ProductSingleLoaded({required this.product});
}

class ProductsError extends ProductsState {
  final String error;
  
  ProductsError({required this.error});
}