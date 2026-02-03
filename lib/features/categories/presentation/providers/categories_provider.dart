// lib/features/categories/presentation/providers/categories_provider.dart

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/categories_collection.dart';
import '../../data/models/category_model.dart';

// Provider instance
final categoriesProvider = 
    NotifierProvider<CategoriesNotifier, CategoriesState>(
      CategoriesNotifier.new,
    );

// Notifier class
class CategoriesNotifier extends Notifier<CategoriesState> {
  late final CategoriesCollection _collection;

  @override
  CategoriesState build() {
    _collection = CategoriesCollection();
    return CategoriesInitial();
  }

  /// Get all categories
  Future<void> getAllCategories() async {
    state = CategoriesLoading();
    
    try {
      final categories = await _collection.getAllCategories();
      state = CategoriesLoaded(categories: categories);
    } catch (e) {
      state = CategoriesError(error: e.toString());
      log('Error in getAllCategories: ${e.toString()}');
    }
  }

  /// Get only active categories (for customer app)
  Future<void> getActiveCategories() async {
    state = CategoriesLoading();
    
    try {
      final categories = await _collection.getActiveCategories();
      state = CategoriesLoaded(categories: categories);
    } catch (e) {
      state = CategoriesError(error: e.toString());
      log('Error in getActiveCategories: ${e.toString()}');
    }
  }

  /// Get single category
  Future<void> getCategory(String categoryId) async {
    state = CategoriesLoading();
    
    try {
      final category = await _collection.getCategory(categoryId);
      
      if (category != null) {
        state = CategorySingleLoaded(category: category);
      } else {
        state = CategoriesError(error: 'Category not found');
      }
    } catch (e) {
      state = CategoriesError(error: e.toString());
      log('Error in getCategory: ${e.toString()}');
    }
  }

  /// Add new category (admin only)
  Future<bool> addCategory(CategoryModel category) async {
    try {
      final success = await _collection.addCategory(category);
      
      if (success) {
        // Refresh the list
        await getAllCategories();
        return true;
      }
      
      return false;
    } catch (e) {
      state = CategoriesError(error: e.toString());
      log('Error in addCategory: ${e.toString()}');
      return false;
    }
  }

  /// Update category
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      final success = await _collection.updateCategory(category);
      
      if (success) {
        // Refresh the list
        await getAllCategories();
        return true;
      }
      
      return false;
    } catch (e) {
      state = CategoriesError(error: e.toString());
      log('Error in updateCategory: ${e.toString()}');
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      final success = await _collection.deleteCategory(categoryId);
      
      if (success) {
        // Refresh the list
        await getAllCategories();
        return true;
      }
      
      return false;
    } catch (e) {
      state = CategoriesError(error: e.toString());
      log('Error in deleteCategory: ${e.toString()}');
      return false;
    }
  }

  /// Toggle category status
  Future<bool> toggleStatus(String categoryId, bool isActive) async {
    try {
      final success = await _collection.toggleCategoryStatus(
        categoryId,
        isActive,
      );
      
      if (success) {
        // Refresh the list
        await getAllCategories();
        return true;
      }
      
      return false;
    } catch (e) {
      state = CategoriesError(error: e.toString());
      log('Error in toggleStatus: ${e.toString()}');
      return false;
    }
  }

  /// Update category order
  Future<bool> updateOrder(String categoryId, int newOrder) async {
    try {
      final success = await _collection.updateCategoryOrder(
        categoryId,
        newOrder,
      );
      
      if (success) {
        // Refresh the list
        await getAllCategories();
        return true;
      }
      
      return false;
    } catch (e) {
      state = CategoriesError(error: e.toString());
      log('Error in updateOrder: ${e.toString()}');
      return false;
    }
  }

  /// Reorder multiple categories
  Future<bool> reorderCategories(List<String> categoryIds) async {
    try {
      bool allSuccess = true;
      
      for (int i = 0; i < categoryIds.length; i++) {
        final success = await _collection.updateCategoryOrder(
          categoryIds[i],
          i,
        );
        
        if (!success) allSuccess = false;
      }
      
      if (allSuccess) {
        // Refresh the list
        await getAllCategories();
        return true;
      }
      
      return false;
    } catch (e) {
      state = CategoriesError(error: e.toString());
      log('Error in reorderCategories: ${e.toString()}');
      return false;
    }
  }
}

// States
abstract class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<CategoryModel> categories;
  
  CategoriesLoaded({required this.categories});
}

class CategorySingleLoaded extends CategoriesState {
  final CategoryModel category;
  
  CategorySingleLoaded({required this.category});
}

class CategoriesError extends CategoriesState {
  final String error;
  
  CategoriesError({required this.error});
}