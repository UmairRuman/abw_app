// lib/features/stores/presentation/providers/stores_provider.dart

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/stores_collection.dart';
import '../../data/models/store_model.dart';

final storesProvider = NotifierProvider<StoresNotifier, StoresState>(
  StoresNotifier.new,
);

class StoresNotifier extends Notifier<StoresState> {
  late final StoresCollection _collection;

  @override
  StoresState build() {
    _collection = StoresCollection();
    return StoresInitial();
  }

  /// Get all stores
  Future<void> getAllStores() async {
    state = StoresLoading();
    
    try {
      final stores = await _collection.getAllStores();
      state = StoresLoaded(stores: stores);
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in getAllStores: ${e.toString()}');
    }
  }

  /// Get stores by category
  Future<void> getStoresByCategory(String categoryId) async {
    state = StoresLoading();
    
    try {
      final stores = await _collection.getStoresByCategory(categoryId);
      state = StoresLoaded(stores: stores);
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in getStoresByCategory: ${e.toString()}');
    }
  }

  /// Get featured stores
  Future<void> getFeaturedStores() async {
    state = StoresLoading();
    
    try {
      final stores = await _collection.getFeaturedStores();
      state = StoresLoaded(stores: stores);
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in getFeaturedStores: ${e.toString()}');
    }
  }

  /// Get pending stores (admin)
  Future<void> getPendingStores() async {
    state = StoresLoading();
    
    try {
      final stores = await _collection.getPendingStores();
      state = StoresLoaded(stores: stores);
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in getPendingStores: ${e.toString()}');
    }
  }

  /// Get approved stores
  Future<void> getApprovedStores() async {
    state = StoresLoading();
    
    try {
      final stores = await _collection.getApprovedStores();
      state = StoresLoaded(stores: stores);
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in getApprovedStores: ${e.toString()}');
    }
  }

  /// Get single store
  Future<void> getStore(String storeId) async {
    state = StoresLoading();
    
    try {
      final store = await _collection.getStore(storeId);
      
      if (store != null) {
        state = StoreSingleLoaded(store: store);
      } else {
        state = StoresError(error: 'Store not found');
      }
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in getStore: ${e.toString()}');
    }
  }

  /// Add store
  Future<bool> addStore(StoreModel store) async {
    try {
      final success = await _collection.addStore(store);
      
      if (success) {
        await getAllStores();
        return true;
      }
      
      return false;
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in addStore: ${e.toString()}');
      return false;
    }
  }

  /// Update store
  Future<bool> updateStore(StoreModel store) async {
    try {
      final success = await _collection.updateStore(store);
      
      if (success) {
        await getAllStores();
        return true;
      }
      
      return false;
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in updateStore: ${e.toString()}');
      return false;
    }
  }

  /// Delete store
  Future<bool> deleteStore(String storeId) async {
    try {
      final success = await _collection.deleteStore(storeId);
      
      if (success) {
        await getAllStores();
        return true;
      }
      
      return false;
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in deleteStore: ${e.toString()}');
      return false;
    }
  }

  /// Approve store
  Future<bool> approveStore(String storeId, String adminId) async {
    try {
      final success = await _collection.approveStore(storeId, adminId);
      
      if (success) {
        await getPendingStores();
        return true;
      }
      
      return false;
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in approveStore: ${e.toString()}');
      return false;
    }
  }

  /// Reject store
  Future<bool> rejectStore(
    String storeId,
    String adminId,
    String reason,
  ) async {
    try {
      final success = await _collection.rejectStore(
        storeId,
        adminId,
        reason,
      );
      
      if (success) {
        await getPendingStores();
        return true;
      }
      
      return false;
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in rejectStore: ${e.toString()}');
      return false;
    }
  }

  /// Search stores
  Future<void> searchStores(String query) async {
    state = StoresLoading();
    
    try {
      final stores = await _collection.searchStores(query);
      state = StoresLoaded(stores: stores);
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in searchStores: ${e.toString()}');
    }
  }

  /// Toggle featured status
  Future<bool> toggleFeaturedStatus(String storeId, bool isFeatured) async {
    try {
      final success = await _collection.toggleFeaturedStatus(
        storeId,
        isFeatured,
      );
      
      if (success) {
        await getAllStores();
        return true;
      }
      
      return false;
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in toggleFeaturedStatus: ${e.toString()}');
      return false;
    }
  }

  /// Toggle store status
  Future<bool> toggleStoreStatus(String storeId, bool isActive) async {
    try {
      final success = await _collection.toggleStoreStatus(storeId, isActive);
      
      if (success) {
        await getAllStores();
        return true;
      }
      
      return false;
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in toggleStoreStatus: ${e.toString()}');
      return false;
    }
  }

  /// Get stores by owner
  Future<void> getStoresByOwner(String ownerId) async {
    state = StoresLoading();
    
    try {
      final stores = await _collection.getStoresByOwner(ownerId);
      state = StoresLoaded(stores: stores);
    } catch (e) {
      state = StoresError(error: e.toString());
      log('Error in getStoresByOwner: ${e.toString()}');
    }
  }
}

// States
abstract class StoresState {}

class StoresInitial extends StoresState {}

class StoresLoading extends StoresState {}

class StoresLoaded extends StoresState {
  final List<StoreModel> stores;
  
  StoresLoaded({required this.stores});
}

class StoreSingleLoaded extends StoresState {
  final StoreModel store;
  
  StoreSingleLoaded({required this.store});
}

class StoresError extends StoresState {
  final String error;
  
  StoresError({required this.error});
}