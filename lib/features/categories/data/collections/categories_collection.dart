// lib/features/categories/data/collections/categories_collection.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoriesCollection {
  // Singleton pattern
  static final CategoriesCollection instance = CategoriesCollection._internal();
  CategoriesCollection._internal();
  
  factory CategoriesCollection() {
    return instance;
  }

  // Firestore collection reference
  static final _categoriesCollection = 
      FirebaseFirestore.instance.collection('categories');

  /// Add a new category
  Future<bool> addCategory(CategoryModel category) async {
    try {
      await _categoriesCollection.doc(category.id).set(category.toJson());
      log('Category added successfully: ${category.id} - ${category.name}');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error adding category: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error adding category: ${e.toString()}');
      return false;
    }
  }

  /// Update an existing category
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      // Update updatedAt timestamp
      final updatedCategory = category.copyWith(updatedAt: DateTime.now());
      
      await _categoriesCollection
          .doc(category.id)
          .update(updatedCategory.toJson());
      
      log('Category updated successfully: ${category.id}');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error updating category: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error updating category: ${e.toString()}');
      return false;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _categoriesCollection.doc(categoryId).delete();
      log('Category deleted successfully: $categoryId');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error deleting category: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error deleting category: ${e.toString()}');
      return false;
    }
  }

  /// Get a single category by ID
  Future<CategoryModel?> getCategory(String categoryId) async {
    try {
      final snapshot = await _categoriesCollection.doc(categoryId).get();
      
      if (snapshot.exists && snapshot.data() != null) {
        return CategoryModel.fromJson(snapshot.data()!);
      }
      
      log('Category not found: $categoryId');
      return null;
    } on FirebaseException catch (e) {
      log('Firebase Error getting category: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      log('Error getting category: ${e.toString()}');
      return null;
    }
  }

  /// Get all categories
  Future<List<CategoryModel>> getAllCategories() async {
    List<CategoryModel> categories = [];
    
    try {
      final snapshot = await _categoriesCollection
          .orderBy('order', descending: false)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          categories.add(CategoryModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${categories.length} categories');
      return categories;
    } on FirebaseException catch (e) {
      log('Firebase Error getting all categories: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting all categories: ${e.toString()}');
      return [];
    }
  }

  /// Get only active categories (for customer app)
  Future<List<CategoryModel>> getActiveCategories() async {
    List<CategoryModel> categories = [];
    
    try {
      final snapshot = await _categoriesCollection
          .where('isActive', isEqualTo: true)
          .orderBy('order', descending: false)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          categories.add(CategoryModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${categories.length} active categories');
      return categories;
    } on FirebaseException catch (e) {
      log('Firebase Error getting active categories: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting active categories: ${e.toString()}');
      return [];
    }
  }

  /// Update category order
  Future<bool> updateCategoryOrder(String categoryId, int newOrder) async {
    try {
      await _categoriesCollection.doc(categoryId).update({
        'order': newOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      log('Category order updated: $categoryId -> $newOrder');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error updating category order: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error updating category order: ${e.toString()}');
      return false;
    }
  }

  /// Toggle category active status
  Future<bool> toggleCategoryStatus(String categoryId, bool isActive) async {
    try {
      await _categoriesCollection.doc(categoryId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      log('Category status toggled: $categoryId -> $isActive');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error toggling category status: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error toggling category status: ${e.toString()}');
      return false;
    }
  }

  /// Get categories count
  Future<int> getCategoriesCount() async {
    try {
      final snapshot = await _categoriesCollection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      log('Error getting categories count: ${e.toString()}');
      return 0;
    }
  }
}