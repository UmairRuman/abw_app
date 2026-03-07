// lib/features/riders/data/collections/riders_collection.dart
// UPDATED: Multi-order, analytics, device lock, cash stats

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/models/rider_model.dart';
import '../../../auth/domain/entities/rider_entity.dart';

class RidersCollection {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _path = 'users'; // Riders stored in 'users' collection

  // ── Streams ─────────────────────────────────────────────────────────────

  Stream<RiderModel?> getRiderStream(String riderId) {
    return _firestore.collection(_path).doc(riderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RiderModel.fromJson({'id': doc.id, ...doc.data()!});
    });
  }

  Future<RiderModel?> getRiderById(String riderId) async {
    try {
      final doc = await _firestore.collection(_path).doc(riderId).get();
      if (!doc.exists || doc.data() == null) return null;
      return RiderModel.fromJson({'id': doc.id, ...doc.data()!});
    } catch (e) {
      return null;
    }
  }

  Future<List<RiderModel>> getAvailableRiders() async {
    try {
      final snapshot =
          await _firestore
              .collection(_path)
              .where('role', isEqualTo: 'rider')
              .where('isApproved', isEqualTo: true)
              .where('status', isEqualTo: 'available')
              .get();
      return snapshot.docs
          .map((doc) => RiderModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── Status ───────────────────────────────────────────────────────────────

  Future<bool> updateRiderStatus(String riderId, RiderStatus status) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Multi-Order Management ───────────────────────────────────────────────

  /// Add an order to rider's active orders list (multi-order support)
  Future<bool> addCurrentOrder(String riderId, String orderId) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'currentOrderIds': FieldValue.arrayUnion([orderId]),
        'status': RiderStatus.busy.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a specific order from rider's active orders list
  /// Automatically sets status back to available if no orders remain
  Future<bool> removeCurrentOrder(String riderId, String orderId) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'currentOrderIds': FieldValue.arrayRemove([orderId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Check remaining orders to decide status
      final doc = await _firestore.collection(_path).doc(riderId).get();
      final remaining = List<String>.from(
        (doc.data()?['currentOrderIds'] as List<dynamic>? ?? []),
      );
      if (remaining.isEmpty) {
        await _firestore.collection(_path).doc(riderId).update({
          'status': RiderStatus.available.name,
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Legacy compat: accepts null to clear all, or a string to add
  Future<bool> updateCurrentOrder(String riderId, String? orderId) async {
    if (orderId != null) {
      return addCurrentOrder(riderId, orderId);
    }
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'currentOrderIds': [],
        'currentOrderId': null,
        'status': RiderStatus.available.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Delivery Stats ───────────────────────────────────────────────────────

  /// Update all delivery stats after completing a delivery.
  /// [collectedCash] is 0.0 for online payments, order.total for COD.
  Future<bool> updateDeliveryStats(
    String riderId, {
    required double deliveryFee,
    required double collectedCash,
    required double distance,
  }) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'totalEarnings': FieldValue.increment(deliveryFee),
        'totalDeliveries': FieldValue.increment(1),
        'totalCollectedCash': FieldValue.increment(collectedCash),
        'totalDistance': FieldValue.increment(distance),
        'todayDeliveries': FieldValue.increment(1),
        'todayCollectedCash': FieldValue.increment(collectedCash),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Legacy: update earnings only (called from old acceptOrder flow)
  Future<bool> updateEarnings(String riderId, double amount) async {
    return updateDeliveryStats(
      riderId,
      deliveryFee: amount,
      collectedCash: 0.0,
      distance: 0.0,
    );
  }

  // ── Admin: Clear Records ─────────────────────────────────────────────────

  /// Admin: Reset today's delivery count and today's collected cash
  Future<bool> clearTodayRecords(String riderId) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'todayDeliveries': 0,
        'todayCollectedCash': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Reset total collected cash to zero
  Future<bool> clearCollectedCash(String riderId) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'totalCollectedCash': 0.0,
        'todayCollectedCash': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Admin: Reset all analytics for a rider (full wipe)
  Future<bool> clearAllAnalytics(String riderId) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'totalDeliveries': 0,
        'totalCollectedCash': 0.0,
        'totalDistance': 0.0,
        'totalEarnings': 0.0,
        'todayDeliveries': 0,
        'todayCollectedCash': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Device Lock ──────────────────────────────────────────────────────────

  /// Returns true if login is allowed (no other device active or same device).
  /// Returns false if a DIFFERENT device is already logged in → block login.
  ///
  /// Call this right after Firebase Auth sign-in succeeds, BEFORE entering the app.
  /// Pass a stable device ID (e.g. from device_info_plus or shared_preferences UUID).
  Future<bool> checkAndSetDevice(String riderId, String deviceId) async {
    try {
      final doc = await _firestore.collection(_path).doc(riderId).get();
      if (!doc.exists) return false;

      final activeDeviceId = doc.data()?['activeDeviceId'] as String?;

      // No device registered yet, or same device logging in again
      if (activeDeviceId == null || activeDeviceId == deviceId) {
        await _firestore.collection(_path).doc(riderId).update({
          'activeDeviceId': deviceId,
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      // A different device is already active → block
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Call on logout to release the device lock
  Future<bool> clearDevice(String riderId) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'activeDeviceId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Admin override: Force clear device lock (useful if rider lost/broke phone)
  Future<bool> adminForceLogoutRider(String riderId) async {
    return clearDevice(riderId);
  }
}
