// lib/features/products/data/collections/products_collection.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductsCollection {
  // Singleton pattern
  static final ProductsCollection instance = ProductsCollection._internal();
  ProductsCollection._internal();
  
  factory ProductsCollection() {
    return instance;
  }

  static final _firestore = FirebaseFirestore.instance;

  /// 🔥 CRITICAL: Add product to BOTH locations using batch write
  Future<bool> addProduct(ProductModel product) async {
    try {
      final batch = _firestore.batch();
      
      // Location 1: Top-level products collection
      final topLevelRef = _firestore
          .collection('products')
          .doc(product.id);
      
      // Location 2: Store subcollection
      final subCollectionRef = _firestore
          .collection('stores')
          .doc(product.storeId)
          .collection('products')
          .doc(product.id);
      
      // Add to both locations
      batch.set(topLevelRef, product.toJson());
      batch.set(subCollectionRef, product.toJson());
      
      // Commit batch
      await batch.commit();
      
      log('Product added to BOTH locations: ${product.id} - ${product.name}');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error adding product: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error adding product: ${e.toString()}');
      return false;
    }
  }

  /// 🔥 CRITICAL: Update product in BOTH locations using batch write
  Future<bool> updateProduct(ProductModel product) async {
    try {
      final batch = _firestore.batch();
      
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      
      // Location 1: Top-level
      final topLevelRef = _firestore
          .collection('products')
          .doc(product.id);
      
      // Location 2: Subcollection
      final subCollectionRef = _firestore
          .collection('stores')
          .doc(product.storeId)
          .collection('products')
          .doc(product.id);
      
      // Update both locations
      batch.update(topLevelRef, updatedProduct.toJson());
      batch.update(subCollectionRef, updatedProduct.toJson());
      
      await batch.commit();
      
      log('Product updated in BOTH locations: ${product.id}');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error updating product: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error updating product: ${e.toString()}');
      return false;
    }
  }

  /// 🔥 CRITICAL: Delete product from BOTH locations using batch write
  Future<bool> deleteProduct(String productId, String storeId) async {
    try {
      final batch = _firestore.batch();
      
      // Location 1: Top-level
      final topLevelRef = _firestore
          .collection('products')
          .doc(productId);
      
      // Location 2: Subcollection
      final subCollectionRef = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(productId);
      
      // Delete from both locations
      batch.delete(topLevelRef);
      batch.delete(subCollectionRef);
      
      await batch.commit();
      
      log('Product deleted from BOTH locations: $productId');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error deleting product: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error deleting product: ${e.toString()}');
      return false;
    }
  }

  /// Get single product (from top-level collection)
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .get();
      
      if (snapshot.exists && snapshot.data() != null) {
        return ProductModel.fromJson(snapshot.data()!);
      }
      
      log('Product not found: $productId');
      return null;
    } on FirebaseException catch (e) {
      log('Firebase Error getting product: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      log('Error getting product: ${e.toString()}');
      return null;
    }
  }

  /// Get products by store (from subcollection)
  Future<List<ProductModel>> getProductsByStore(String storeId) async {
    List<ProductModel> products = [];
    
    try {
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          products.add(ProductModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${products.length} products for store: $storeId');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase Error getting products by store: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting products by store: ${e.toString()}');
      return [];
    }
  }

  /// Get all products (from top-level collection)
  Future<List<ProductModel>> getAllProducts() async {
    List<ProductModel> products = [];
    
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          products.add(ProductModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${products.length} products');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase Error getting all products: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting all products: ${e.toString()}');
      return [];
    }
  }

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    List<ProductModel> products = [];
    
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .where('isAvailable', isEqualTo: true)
          .orderBy('totalSold', descending: true)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          products.add(ProductModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${products.length} products for category: $categoryId');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase Error getting products by category: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting products by category: ${e.toString()}');
      return [];
    }
  }

  /// Get featured products
  Future<List<ProductModel>> getFeaturedProducts() async {
    List<ProductModel> products = [];
    
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isFeatured', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .orderBy('totalSold', descending: true)
          .limit(20)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          products.add(ProductModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${products.length} featured products');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase Error getting featured products: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting featured products: ${e.toString()}');
      return [];
    }
  }

  /// Get popular products
  Future<List<ProductModel>> getPopularProducts() async {
    List<ProductModel> products = [];
    
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isPopular', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .orderBy('totalSold', descending: true)
          .limit(20)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          products.add(ProductModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${products.length} popular products');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase Error getting popular products: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting popular products: ${e.toString()}');
      return [];
    }
  }

  /// Search products (global)
  Future<List<ProductModel>> searchProducts(String query) async {
    List<ProductModel> products = [];
    
    if (query.isEmpty) return products;
    
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .get();
      
      final lowerQuery = query.toLowerCase();
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          final product = ProductModel.fromJson(doc.data());
          if (product.name.toLowerCase().contains(lowerQuery) ||
              product.description.toLowerCase().contains(lowerQuery)) {
            products.add(product);
          }
        }
      }
      
      log('Found ${products.length} products matching: $query');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase Error searching products: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error searching products: ${e.toString()}');
      return [];
    }
  }

  /// Search products in specific store
  Future<List<ProductModel>> searchProductsInStore(
    String storeId,
    String query,
  ) async {
    List<ProductModel> products = [];
    
    if (query.isEmpty) return products;
    
    try {
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .get();
      
      final lowerQuery = query.toLowerCase();
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          final product = ProductModel.fromJson(doc.data());
          if (product.name.toLowerCase().contains(lowerQuery)) {
            products.add(product);
          }
        }
      }
      
      log('Found ${products.length} products in store matching: $query');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase Error searching products in store: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error searching products in store: ${e.toString()}');
      return [];
    }
  }

  /// 🔥 Update product stock in BOTH locations
  Future<bool> updateProductStock(String productId, String storeId, int newQuantity) async {
    try {
      final batch = _firestore.batch();
      
      final updates = {
        'quantity': newQuantity,
        'isAvailable': newQuantity > 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Location 1: Top-level
      final topLevelRef = _firestore
          .collection('products')
          .doc(productId);
      
      // Location 2: Subcollection
      final subCollectionRef = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(productId);
      
      batch.update(topLevelRef, updates);
      batch.update(subCollectionRef, updates);
      
      await batch.commit();
      
      log('Product stock updated in BOTH locations: $productId -> $newQuantity');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error updating stock: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error updating stock: ${e.toString()}');
      return false;
    }
  }

  /// 🔥 Toggle product availability in BOTH locations
  Future<bool> toggleProductAvailability(
    String productId,
    String storeId,
    bool isAvailable,
  ) async {
    try {
      final batch = _firestore.batch();
      
      final updates = {
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final topLevelRef = _firestore
          .collection('products')
          .doc(productId);
      
      final subCollectionRef = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(productId);
      
      batch.update(topLevelRef, updates);
      batch.update(subCollectionRef, updates);
      
      await batch.commit();
      
      log('Product availability toggled in BOTH locations: $productId -> $isAvailable');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error toggling availability: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error toggling availability: ${e.toString()}');
      return false;
    }
  }

  /// Get products by price range
  Future<List<ProductModel>> getProductsByPriceRange(
    double min,
    double max,
  ) async {
    List<ProductModel> products = [];
    
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .where('price', isGreaterThanOrEqualTo: min)
          .where('price', isLessThanOrEqualTo: max)
          .orderBy('price', descending: false)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          products.add(ProductModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${products.length} products in price range: $min - $max');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase Error getting products by price: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting products by price: ${e.toString()}');
      return [];
    }
  }
}