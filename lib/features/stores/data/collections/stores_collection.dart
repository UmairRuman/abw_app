// lib/features/stores/data/collections/stores_collection.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';

class StoresCollection {
  // Singleton pattern
  static final StoresCollection instance = StoresCollection._internal();
  StoresCollection._internal();
  
  factory StoresCollection() {
    return instance;
  }

  static final _storesCollection = 
      FirebaseFirestore.instance.collection('stores');

  /// Add new store
  Future<bool> addStore(StoreModel store) async {
    try {
      await _storesCollection.doc(store.id).set(store.toJson());
      log('Store added successfully: ${store.id} - ${store.name}');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error adding store: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error adding store: ${e.toString()}');
      return false;
    }
  }

  /// Update store
  Future<bool> updateStore(StoreModel store) async {
    try {
      final updatedStore = store.copyWith(updatedAt: DateTime.now());
      
      await _storesCollection
          .doc(store.id)
          .update(updatedStore.toJson());
      
      log('Store updated successfully: ${store.id}');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error updating store: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error updating store: ${e.toString()}');
      return false;
    }
  }

  /// Delete store
  Future<bool> deleteStore(String storeId) async {
    try {
      await _storesCollection.doc(storeId).delete();
      log('Store deleted successfully: $storeId');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error deleting store: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error deleting store: ${e.toString()}');
      return false;
    }
  }

  /// Get single store
  Future<StoreModel?> getStore(String storeId) async {
    try {
      final snapshot = await _storesCollection.doc(storeId).get();
      
      if (snapshot.exists && snapshot.data() != null) {
        return StoreModel.fromJson(snapshot.data()!);
      }
      
      log('Store not found: $storeId');
      return null;
    } on FirebaseException catch (e) {
      log('Firebase Error getting store: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      log('Error getting store: ${e.toString()}');
      return null;
    }
  }

  /// Get all stores
  Future<List<StoreModel>> getAllStores() async {
    List<StoreModel> stores = [];
    
    try {
      final snapshot = await _storesCollection
          .orderBy('createdAt', descending: true)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          stores.add(StoreModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${stores.length} stores');
      return stores;
    } on FirebaseException catch (e) {
      log('Firebase Error getting all stores: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting all stores: ${e.toString()}');
      return [];
    }
  }

  /// Get stores by category
  Future<List<StoreModel>> getStoresByCategory(String categoryId) async {
    List<StoreModel> stores = [];
    
    try {
      final snapshot = await _storesCollection
          .where('categoryId', isEqualTo: categoryId)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          stores.add(StoreModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${stores.length} stores for category: $categoryId');
      return stores;
    } on FirebaseException catch (e) {
      log('Firebase Error getting stores by category: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting stores by category: ${e.toString()}');
      return [];
    }
  }

  /// Get pending stores (for admin approval)
  Future<List<StoreModel>> getPendingStores() async {
    List<StoreModel> stores = [];
    
    try {
      final snapshot = await _storesCollection
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          stores.add(StoreModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${stores.length} pending stores');
      return stores;
    } on FirebaseException catch (e) {
      log('Firebase Error getting pending stores: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting pending stores: ${e.toString()}');
      return [];
    }
  }

  /// Get approved stores
  Future<List<StoreModel>> getApprovedStores() async {
    List<StoreModel> stores = [];
    
    try {
      final snapshot = await _storesCollection
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          stores.add(StoreModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${stores.length} approved stores');
      return stores;
    } on FirebaseException catch (e) {
      log('Firebase Error getting approved stores: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting approved stores: ${e.toString()}');
      return [];
    }
  }

  /// Get featured stores
  Future<List<StoreModel>> getFeaturedStores() async {
    List<StoreModel> stores = [];
    
    try {
      final snapshot = await _storesCollection
          .where('isFeatured', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(10)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          stores.add(StoreModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${stores.length} featured stores');
      return stores;
    } on FirebaseException catch (e) {
      log('Firebase Error getting featured stores: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting featured stores: ${e.toString()}');
      return [];
    }
  }

  /// Approve store (admin)
  Future<bool> approveStore(String storeId, String adminId) async {
    try {
      await _storesCollection.doc(storeId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminId,
        'rejectionReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      log('Store approved: $storeId by admin: $adminId');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error approving store: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error approving store: ${e.toString()}');
      return false;
    }
  }

  /// Reject store (admin)
  Future<bool> rejectStore(
    String storeId,
    String adminId,
    String reason,
  ) async {
    try {
      await _storesCollection.doc(storeId).update({
        'isApproved': false,
        'approvedAt': null,
        'approvedBy': adminId,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      log('Store rejected: $storeId by admin: $adminId. Reason: $reason');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error rejecting store: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error rejecting store: ${e.toString()}');
      return false;
    }
  }

  /// Toggle store active status
  Future<bool> toggleStoreStatus(String storeId, bool isActive) async {
    try {
      await _storesCollection.doc(storeId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      log('Store status toggled: $storeId -> $isActive');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error toggling store status: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error toggling store status: ${e.toString()}');
      return false;
    }
  }

  /// Toggle featured status
  Future<bool> toggleFeaturedStatus(String storeId, bool isFeatured) async {
    try {
      await _storesCollection.doc(storeId).update({
        'isFeatured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      log('Store featured status toggled: $storeId -> $isFeatured');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error toggling featured status: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error toggling featured status: ${e.toString()}');
      return false;
    }
  }

  /// Search stores by name
  Future<List<StoreModel>> searchStores(String query) async {
    List<StoreModel> stores = [];
    
    if (query.isEmpty) return stores;
    
    try {
      // Get all approved stores (Firestore doesn't support case-insensitive search)
      final snapshot = await _storesCollection
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Filter locally
      final lowerQuery = query.toLowerCase();
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          final store = StoreModel.fromJson(doc.data());
          if (store.name.toLowerCase().contains(lowerQuery)) {
            stores.add(store);
          }
        }
      }
      
      log('Found ${stores.length} stores matching: $query');
      return stores;
    } on FirebaseException catch (e) {
      log('Firebase Error searching stores: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error searching stores: ${e.toString()}');
      return [];
    }
  }

  /// Get stores by owner
  Future<List<StoreModel>> getStoresByOwner(String ownerId) async {
    List<StoreModel> stores = [];
    
    try {
      final snapshot = await _storesCollection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          stores.add(StoreModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${stores.length} stores for owner: $ownerId');
      return stores;
    } on FirebaseException catch (e) {
      log('Firebase Error getting stores by owner: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting stores by owner: ${e.toString()}');
      return [];
    }
  }

  /// Update store rating
  Future<bool> updateRating(
    String storeId,
    double newRating,
    int totalReviews,
  ) async {
    try {
      await _storesCollection.doc(storeId).update({
        'rating': newRating,
        'totalReviews': totalReviews,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      log('Store rating updated: $storeId -> $newRating ($totalReviews reviews)');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error updating store rating: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error updating store rating: ${e.toString()}');
      return false;
    }
  }

  /// Increment total orders
  Future<bool> incrementTotalOrders(String storeId) async {
    try {
      await _storesCollection.doc(storeId).update({
        'totalOrders': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      log('Store total orders incremented: $storeId');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error incrementing orders: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error incrementing orders: ${e.toString()}');
      return false;
    }
  }
}