// lib/features/search/presentation/providers/search_provider.dart

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/data/collections/products_collection.dart';
import '../../../products/data/models/product_model.dart';
import '../../../stores/data/collections/stores_collection.dart';
import '../../../stores/data/models/store_model.dart';

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

class SearchNotifier extends Notifier<SearchState> {
  late final ProductsCollection _productsCollection;
  late final StoresCollection _storesCollection;

  @override
  SearchState build() {
    _productsCollection = ProductsCollection();
    _storesCollection = StoresCollection();
    return SearchInitial();
  }

  /// Search both products and stores
  Future<void> searchAll(String query) async {
    if (query.isEmpty) {
      state = SearchInitial();
      return;
    }

    state = SearchLoading();
    
    try {
      // Search products and stores in parallel
      final results = await Future.wait([
        _productsCollection.searchProducts(query),
        _storesCollection.searchStores(query),
      ]);

      final products = results[0] as List<ProductModel>;
      final stores = results[1] as List<StoreModel>;

      state = SearchLoaded(
        products: products,
        stores: stores,
        hasResults: products.isNotEmpty || stores.isNotEmpty,
      );

      log('Search results: ${products.length} products, ${stores.length} stores');
    } catch (e) {
      state = SearchError(error: e.toString());
      log('Error in searchAll: ${e.toString()}');
    }
  }

  /// Search products only
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      state = SearchInitial();
      return;
    }

    state = SearchLoading();
    
    try {
      final products = await _productsCollection.searchProducts(query);
      
      state = SearchLoaded(
        products: products,
        stores: [],
        hasResults: products.isNotEmpty,
      );

      log('Found ${products.length} products');
    } catch (e) {
      state = SearchError(error: e.toString());
      log('Error in searchProducts: ${e.toString()}');
    }
  }

  /// Search stores only
  Future<void> searchStores(String query) async {
    if (query.isEmpty) {
      state = SearchInitial();
      return;
    }

    state = SearchLoading();
    
    try {
      final stores = await _storesCollection.searchStores(query);
      
      state = SearchLoaded(
        products: [],
        stores: stores,
        hasResults: stores.isNotEmpty,
      );

      log('Found ${stores.length} stores');
    } catch (e) {
      state = SearchError(error: e.toString());
      log('Error in searchStores: ${e.toString()}');
    }
  }

  /// Clear search
  void clearSearch() {
    state = SearchInitial();
  }

  // Helper methods for recent searches (stored locally)
  final List<String> _recentSearches = [];

  void saveRecentSearch(String query) {
    if (query.isEmpty) return;
    
    // Remove if already exists
    _recentSearches.remove(query);
    
    // Add to beginning
    _recentSearches.insert(0, query);
    
    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }

    log('Recent search saved: $query');
  }

  List<String> getRecentSearches() {
    return List.from(_recentSearches);
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    log('Recent searches cleared');
  }

  void removeRecentSearch(String query) {
    _recentSearches.remove(query);
    log('Recent search removed: $query');
  }
}

// States
abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<ProductModel> products;
  final List<StoreModel> stores;
  final bool hasResults;

  SearchLoaded({
    required this.products,
    required this.stores,
    required this.hasResults,
  });
}

class SearchError extends SearchState {
  final String error;
  
  SearchError({required this.error});
}