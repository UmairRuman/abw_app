// lib/features/addresses/presentation/providers/addresses_provider.dart

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/addresses_collection.dart';
import '../../data/models/address_model.dart';

final addressesProvider = NotifierProvider<AddressesNotifier, AddressesState>(
  AddressesNotifier.new,
);

class AddressesNotifier extends Notifier<AddressesState> {
  late final AddressesCollection _collection;

  @override
  AddressesState build() {
    _collection = AddressesCollection();
    return AddressesInitial();
  }

  /// Load all user addresses
  Future<void> loadUserAddresses(String userId) async {
    state = AddressesLoading();
    
    try {
      final addresses = await _collection.getUserAddresses(userId);
      state = AddressesLoaded(addresses: addresses);
    } catch (e) {
      state = AddressesError(error: e.toString());
      log('Error in loadUserAddresses: ${e.toString()}');
    }
  }

  /// Load default address
  Future<void> loadDefaultAddress(String userId) async {
    state = AddressesLoading();
    
    try {
      final address = await _collection.getDefaultAddress(userId);
      
      if (address != null) {
        state = AddressSingleLoaded(address: address);
      } else {
        state = AddressesError(error: 'No default address found');
      }
    } catch (e) {
      state = AddressesError(error: e.toString());
      log('Error in loadDefaultAddress: ${e.toString()}');
    }
  }

  /// Get single address
  Future<void> getAddress(String addressId) async {
    state = AddressesLoading();
    
    try {
      final address = await _collection.getAddress(addressId);
      
      if (address != null) {
        state = AddressSingleLoaded(address: address);
      } else {
        state = AddressesError(error: 'Address not found');
      }
    } catch (e) {
      state = AddressesError(error: e.toString());
      log('Error in getAddress: ${e.toString()}');
    }
  }

  /// Add new address
  Future<bool> addAddress(AddressModel address) async {
    try {
      final addressId = await _collection.addAddress(address);
      
      if (addressId != null) {
        await loadUserAddresses(address.userId);
        return true;
      }
      
      return false;
    } catch (e) {
      state = AddressesError(error: e.toString());
      log('Error in addAddress: ${e.toString()}');
      return false;
    }
  }

  /// Update address
  Future<bool> updateAddress(AddressModel address) async {
    try {
      final success = await _collection.updateAddress(address);
      
      if (success) {
        await loadUserAddresses(address.userId);
        return true;
      }
      
      return false;
    } catch (e) {
      state = AddressesError(error: e.toString());
      log('Error in updateAddress: ${e.toString()}');
      return false;
    }
  }

  /// Delete address
  Future<bool> deleteAddress(String addressId, String userId) async {
    try {
      final success = await _collection.deleteAddress(addressId);
      
      if (success) {
        await loadUserAddresses(userId);
        return true;
      }
      
      return false;
    } catch (e) {
      state = AddressesError(error: e.toString());
      log('Error in deleteAddress: ${e.toString()}');
      return false;
    }
  }

  /// Set default address
  Future<bool> setDefaultAddress(String addressId, String userId) async {
    try {
      final success = await _collection.setDefaultAddress(addressId, userId);
      
      if (success) {
        await loadUserAddresses(userId);
        return true;
      }
      
      return false;
    } catch (e) {
      state = AddressesError(error: e.toString());
      log('Error in setDefaultAddress: ${e.toString()}');
      return false;
    }
  }

  /// Validate address
  bool validateAddress(AddressModel address) {
    if (address.name.isEmpty) return false;
    if (address.phone.isEmpty) return false;
    if (address.addressLine1.isEmpty) return false;
    if (address.area.isEmpty) return false;
    if (address.city.isEmpty) return false;
  
    
    // Validate phone number (simple check)
    if (address.phone.length < 10) return false;
    
    return true;
  }

  // UI Helper methods
  bool hasDefaultAddress() {
    if (state is AddressesLoaded) {
      final addresses = (state as AddressesLoaded).addresses;
      return addresses.any((address) => address.isDefault);
    }
    return false;
  }

  int getAddressCount() {
    if (state is AddressesLoaded) {
      return (state as AddressesLoaded).addresses.length;
    }
    return 0;
  }

  bool canAddMore({int maxAddresses = 5}) {
    return getAddressCount() < maxAddresses;
  }
}

// States
abstract class AddressesState {}

class AddressesInitial extends AddressesState {}

class AddressesLoading extends AddressesState {}

class AddressesLoaded extends AddressesState {
  final List<AddressModel> addresses;
  
  AddressesLoaded({required this.addresses});
}

class AddressSingleLoaded extends AddressesState {
  final AddressModel address;
  
  AddressSingleLoaded({required this.address});
}

class AddressesError extends AddressesState {
  final String error;
  
  AddressesError({required this.error});
}