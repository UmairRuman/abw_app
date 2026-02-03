// lib/features/addresses/data/collections/addresses_collection.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';

class AddressesCollection {
  // Singleton pattern
  static final AddressesCollection instance = AddressesCollection._internal();
  AddressesCollection._internal();
  
  factory AddressesCollection() {
    return instance;
  }

  static final _addressesCollection = 
      FirebaseFirestore.instance.collection('addresses');

  /// Add new address
  Future<String?> addAddress(AddressModel address) async {
    try {
      // If this address is set as default, unset other defaults first
      if (address.isDefault) {
        await _unsetAllDefaults(address.userId);
      }

      await _addressesCollection.doc(address.id).set(address.toJson());
      
      log('Address added successfully: ${address.id}');
      return address.id;
    } on FirebaseException catch (e) {
      log('Firebase Error adding address: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      log('Error adding address: ${e.toString()}');
      return null;
    }
  }

  /// Update address
  Future<bool> updateAddress(AddressModel address) async {
    try {
      // If setting as default, unset other defaults first
      if (address.isDefault) {
        await _unsetAllDefaults(address.userId);
      }

      final updatedAddress = address.copyWith(updatedAt: DateTime.now());
      
      await _addressesCollection
          .doc(address.id)
          .update(updatedAddress.toJson());
      
      log('Address updated successfully: ${address.id}');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error updating address: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error updating address: ${e.toString()}');
      return false;
    }
  }

  /// Delete address
  Future<bool> deleteAddress(String addressId) async {
    try {
      await _addressesCollection.doc(addressId).delete();
      log('Address deleted successfully: $addressId');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error deleting address: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error deleting address: ${e.toString()}');
      return false;
    }
  }

  /// Get single address
  Future<AddressModel?> getAddress(String addressId) async {
    try {
      final snapshot = await _addressesCollection.doc(addressId).get();
      
      if (snapshot.exists && snapshot.data() != null) {
        return AddressModel.fromJson(snapshot.data()!);
      }
      
      log('Address not found: $addressId');
      return null;
    } on FirebaseException catch (e) {
      log('Firebase Error getting address: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      log('Error getting address: ${e.toString()}');
      return null;
    }
  }

  /// Get all user addresses
  Future<List<AddressModel>> getUserAddresses(String userId) async {
    List<AddressModel> addresses = [];
    
    try {
      final snapshot = await _addressesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('isDefault', descending: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          addresses.add(AddressModel.fromJson(doc.data()));
        }
      }
      
      log('Fetched ${addresses.length} addresses for user: $userId');
      return addresses;
    } on FirebaseException catch (e) {
      log('Firebase Error getting user addresses: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      log('Error getting user addresses: ${e.toString()}');
      return [];
    }
  }

  /// Get default address
  Future<AddressModel?> getDefaultAddress(String userId) async {
    try {
      final snapshot = await _addressesCollection
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty && snapshot.docs.first.data() != null) {
        return AddressModel.fromJson(snapshot.docs.first.data());
      }
      
      log('No default address found for user: $userId');
      return null;
    } on FirebaseException catch (e) {
      log('Firebase Error getting default address: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      log('Error getting default address: ${e.toString()}');
      return null;
    }
  }

  /// Set address as default
  Future<bool> setDefaultAddress(String addressId, String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Step 1: Unset all defaults for this user
      final userAddresses = await getUserAddresses(userId);
      for (var address in userAddresses) {
        if (address.isDefault) {
          final ref = _addressesCollection.doc(address.id);
          batch.update(ref, {
            'isDefault': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      // Step 2: Set new default
      final newDefaultRef = _addressesCollection.doc(addressId);
      batch.update(newDefaultRef, {
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
      log('Default address set: $addressId');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error setting default address: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error setting default address: ${e.toString()}');
      return false;
    }
  }

  /// Count user addresses
  Future<int> countUserAddresses(String userId) async {
    try {
      final snapshot = await _addressesCollection
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      log('Error counting addresses: ${e.toString()}');
      return 0;
    }
  }

  /// Private helper: Unset all default addresses for user
  Future<void> _unsetAllDefaults(String userId) async {
    try {
      final snapshot = await _addressesCollection
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isDefault': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      log('All defaults unset for user: $userId');
    } catch (e) {
      log('Error unsetting defaults: ${e.toString()}');
    }
  }
}