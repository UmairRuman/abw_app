// lib/features/blocked_numbers/data/collections/blocked_numbers_collection.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blocked_number_model.dart';

class BlockedNumbersCollection {
  static final BlockedNumbersCollection instance =
      BlockedNumbersCollection._internal();
  BlockedNumbersCollection._internal();

  static final _collection = FirebaseFirestore.instance.collection(
    'blocked_numbers',
  );

  factory BlockedNumbersCollection() {
    return instance;
  }

  /// Block a phone number
  Future<bool> blockNumber(BlockedNumberModel blockedNumber) async {
    try {
      await _collection.doc(blockedNumber.id).set(blockedNumber.toJson());
      log('Number blocked successfully: ${blockedNumber.phoneNumber}');
      return true;
    } catch (e) {
      log('Error blocking number: ${e.toString()}');
      return false;
    }
  }

  /// Unblock a phone number (soft delete - set isActive to false)
  Future<bool> unblockNumber(String blockId) async {
    try {
      await _collection.doc(blockId).update({'isActive': false});
      log('Number unblocked successfully: $blockId');
      return true;
    } catch (e) {
      log('Error unblocking number: ${e.toString()}');
      return false;
    }
  }

  /// Permanently delete a blocked number
  Future<bool> deleteBlockedNumber(String blockId) async {
    try {
      await _collection.doc(blockId).delete();
      log('Blocked number deleted successfully: $blockId');
      return true;
    } catch (e) {
      log('Error deleting blocked number: ${e.toString()}');
      return false;
    }
  }

  /// Check if a phone number is blocked
  Future<bool> isNumberBlocked(String phoneNumber) async {
    try {
      final snapshot =
          await _collection
              .where('phoneNumber', isEqualTo: phoneNumber)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      log('Error checking if number is blocked: ${e.toString()}');
      return false;
    }
  }

  /// Get blocked number details
  Future<BlockedNumberModel?> getBlockedNumber(String blockId) async {
    try {
      final doc = await _collection.doc(blockId).get();
      if (doc.exists) {
        return BlockedNumberModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      log('Error getting blocked number: ${e.toString()}');
      return null;
    }
  }

  /// Get blocked number by phone
  Future<BlockedNumberModel?> getBlockedNumberByPhone(
    String phoneNumber,
  ) async {
    try {
      final snapshot =
          await _collection
              .where('phoneNumber', isEqualTo: phoneNumber)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return BlockedNumberModel.fromJson(data);
      }
      return null;
    } catch (e) {
      log('Error getting blocked number by phone: ${e.toString()}');
      return null;
    }
  }

  /// Get all blocked numbers
  Future<List<BlockedNumberModel>> getAllBlockedNumbers() async {
    try {
      final snapshot =
          await _collection
              .where('isActive', isEqualTo: true)
              .orderBy('blockedAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BlockedNumberModel.fromJson(data);
      }).toList();
    } catch (e) {
      log('Error getting all blocked numbers: ${e.toString()}');
      return [];
    }
  }

  /// Get blocked numbers by admin
  Future<List<BlockedNumberModel>> getBlockedNumbersByAdmin(
    String adminId,
  ) async {
    try {
      final snapshot =
          await _collection
              .where('blockedBy', isEqualTo: adminId)
              .where('isActive', isEqualTo: true)
              .orderBy('blockedAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BlockedNumberModel.fromJson(data);
      }).toList();
    } catch (e) {
      log('Error getting blocked numbers by admin: ${e.toString()}');
      return [];
    }
  }

  /// Search blocked numbers by phone
  Future<List<BlockedNumberModel>> searchBlockedNumbers(String query) async {
    try {
      // Note: Firestore doesn't support contains queries
      // This fetches all and filters locally (fine for small datasets)
      final snapshot =
          await _collection.where('isActive', isEqualTo: true).get();

      return snapshot.docs
          .map((doc) => BlockedNumberModel.fromJson(doc.data()))
          .where((block) => block.phoneNumber.contains(query))
          .toList();
    } catch (e) {
      log('Error searching blocked numbers: ${e.toString()}');
      return [];
    }
  }
}
