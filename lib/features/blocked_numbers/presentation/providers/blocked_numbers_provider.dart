// lib/features/blocked_numbers/presentation/providers/blocked_numbers_provider.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/blocked_numbers_collection.dart';
import '../../data/models/blocked_number_model.dart';

final blockedNumbersProvider =
    NotifierProvider<BlockedNumbersNotifier, BlockedNumbersState>(
      BlockedNumbersNotifier.new,
    );

class BlockedNumbersNotifier extends Notifier<BlockedNumbersState> {
  late final BlockedNumbersCollection _collection;

  @override
  BlockedNumbersState build() {
    _collection = BlockedNumbersCollection();
    return BlockedNumbersInitial();
  }

  /// Load all blocked numbers
  Future<void> loadBlockedNumbers() async {
    state = BlockedNumbersLoading();

    try {
      final numbers = await _collection.getAllBlockedNumbers();
      state = BlockedNumbersLoaded(numbers: numbers);
    } catch (e) {
      state = BlockedNumbersError(error: e.toString());
      log('Error loading blocked numbers: ${e.toString()}');
    }
  }

  /// Block a phone number
  Future<bool> blockNumber({
    required String phoneNumber,
    required String blockedBy,
    required String blockedByName,
    required String reason,
    String? userId,
  }) async {
    try {
      // Check if already blocked
      final isBlocked = await _collection.isNumberBlocked(phoneNumber);
      if (isBlocked) {
        state = BlockedNumbersError(error: 'This number is already blocked');
        return false;
      }

      final blockId =
          FirebaseFirestore.instance.collection('blocked_numbers').doc().id;

      final blockedNumber = BlockedNumberModel(
        id: blockId,
        phoneNumber: phoneNumber,
        userId: userId,
        blockedBy: blockedBy,
        blockedByName: blockedByName,
        reason: reason,
        blockedAt: DateTime.now(),
        isActive: true,
      );

      final success = await _collection.blockNumber(blockedNumber);

      if (success) {
        await loadBlockedNumbers(); // Refresh list
        return true;
      }

      return false;
    } catch (e) {
      state = BlockedNumbersError(error: e.toString());
      log('Error blocking number: ${e.toString()}');
      return false;
    }
  }

  /// Unblock a phone number
  Future<bool> unblockNumber(String blockId) async {
    try {
      final success = await _collection.unblockNumber(blockId);

      if (success) {
        await loadBlockedNumbers(); // Refresh list
        return true;
      }

      return false;
    } catch (e) {
      state = BlockedNumbersError(error: e.toString());
      log('Error unblocking number: ${e.toString()}');
      return false;
    }
  }

  /// Delete blocked number permanently
  Future<bool> deleteBlockedNumber(String blockId) async {
    try {
      final success = await _collection.deleteBlockedNumber(blockId);

      if (success) {
        await loadBlockedNumbers(); // Refresh list
        return true;
      }

      return false;
    } catch (e) {
      state = BlockedNumbersError(error: e.toString());
      log('Error deleting blocked number: ${e.toString()}');
      return false;
    }
  }

  /// Check if number is blocked (for order verification)
  Future<bool> isNumberBlocked(String phoneNumber) async {
    try {
      return await _collection.isNumberBlocked(phoneNumber);
    } catch (e) {
      log('Error checking if number is blocked: ${e.toString()}');
      return false;
    }
  }

  /// Search blocked numbers
  Future<void> searchBlockedNumbers(String query) async {
    state = BlockedNumbersLoading();

    try {
      final numbers = await _collection.searchBlockedNumbers(query);
      state = BlockedNumbersLoaded(numbers: numbers);
    } catch (e) {
      state = BlockedNumbersError(error: e.toString());
      log('Error searching blocked numbers: ${e.toString()}');
    }
  }
}

// States
abstract class BlockedNumbersState {}

class BlockedNumbersInitial extends BlockedNumbersState {}

class BlockedNumbersLoading extends BlockedNumbersState {}

class BlockedNumbersLoaded extends BlockedNumbersState {
  final List<BlockedNumberModel> numbers;

  BlockedNumbersLoaded({required this.numbers});
}

class BlockedNumbersError extends BlockedNumbersState {
  final String error;

  BlockedNumbersError({required this.error});
}
