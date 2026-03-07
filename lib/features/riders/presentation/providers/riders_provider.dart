// lib/features/riders/presentation/providers/riders_provider.dart
// UPDATED: Multi-order, analytics, device lock, cash check-in

import 'package:abw_app/features/auth/data/models/rider_model.dart';
import 'package:abw_app/features/auth/domain/entities/rider_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/riders_collection.dart';
import '../../../orders/data/collections/orders_collection.dart';
import '../../../orders/domain/entities/order_entity.dart';

// ── States ───────────────────────────────────────────────────────────────────

abstract class RidersState {}

class RidersInitial extends RidersState {}

class RidersLoading extends RidersState {}

class RidersLoaded extends RidersState {
  final List<RiderModel> riders;
  RidersLoaded(this.riders);
}

class RiderLoaded extends RidersState {
  final RiderModel rider;
  RiderLoaded(this.rider);
}

class RidersError extends RidersState {
  final String message;
  RidersError(this.message);
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class RidersNotifier extends StateNotifier<RidersState> {
  final RidersCollection _collection = RidersCollection();
  final OrdersCollection _ordersCollection = OrdersCollection();

  RidersNotifier() : super(RidersInitial());

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> getAvailableRiders() async {
    state = RidersLoading();
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('isApproved', isEqualTo: true)
              .where('isActive', isEqualTo: true)
              .get();

      final riders =
          snapshot.docs
              .map((doc) => RiderModel.fromJson({'id': doc.id, ...doc.data()}))
              .toList();

      state = RidersLoaded(riders);
    } catch (e) {
      state = RidersError(e.toString());
    }
  }

  Future<void> getRiderById(String riderId) async {
    state = RidersLoading();
    try {
      final rider = await _collection.getRiderById(riderId);
      if (rider != null) {
        state = RiderLoaded(rider);
      } else {
        state = RidersError('Rider not found');
      }
    } catch (e) {
      state = RidersError(e.toString());
    }
  }

  // ── Status ────────────────────────────────────────────────────────────────

  Future<bool> toggleAvailability(String riderId, RiderStatus newStatus) async {
    try {
      return await _collection.updateRiderStatus(riderId, newStatus);
    } catch (e) {
      return false;
    }
  }

  // ── Multi-Order: Accept ───────────────────────────────────────────────────

  /// Rider accepts an order. Supports multiple simultaneous orders.
  /// No longer blocks if rider already has an active order.
  Future<bool> acceptOrder(String riderId, String orderId) async {
    try {
      // Add to rider's active orders list (not replace)
      await _collection.addCurrentOrder(riderId, orderId);

      // Update order status
      await _ordersCollection.updateOrderStatus(
        orderId,
        OrderStatus.outForDelivery,
        'Rider accepted and is picking up order',
        riderId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Multi-Order: Complete ─────────────────────────────────────────────────

  /// Mark a specific order as delivered and update rider stats.
  /// [collectedCash] = order.total for COD, 0.0 for online payment.
  /// [distance] = order.distance ?? 0.0
  Future<bool> markDelivered(
    String riderId,
    String orderId, {
    required double deliveryFee,
    required double collectedCash,
    required double distance,
  }) async {
    try {
      // Update order to delivered
      await _ordersCollection.updateOrderStatus(
        orderId,
        OrderStatus.delivered,
        'Order delivered successfully',
        riderId,
      );

      // Remove from rider's active list
      await _collection.removeCurrentOrder(riderId, orderId);

      // Update all stats
      await _collection.updateDeliveryStats(
        riderId,
        deliveryFee: deliveryFee,
        collectedCash: collectedCash,
        distance: distance,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Cash Check-In ─────────────────────────────────────────────────────────

  /// Rider confirms they physically received cash from customer.
  /// Admin will see this flag in the dashboard.
  Future<bool> cashCheckIn(
    String riderId,
    String orderId,
    double amount,
  ) async {
    try {
      return await _ordersCollection.cashCheckIn(orderId, riderId, amount);
    } catch (e) {
      return false;
    }
  }

  // ── Admin: Clear Records ──────────────────────────────────────────────────

  Future<bool> clearTodayRecords(String riderId) async {
    try {
      return await _collection.clearTodayRecords(riderId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearCollectedCash(String riderId) async {
    try {
      return await _collection.clearCollectedCash(riderId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearAllAnalytics(String riderId) async {
    try {
      return await _collection.clearAllAnalytics(riderId);
    } catch (e) {
      return false;
    }
  }

  // ── Device Lock ───────────────────────────────────────────────────────────

  /// Call after login. Returns false if another device is active.
  Future<bool> checkAndSetDevice(String riderId, String deviceId) async {
    try {
      return await _collection.checkAndSetDevice(riderId, deviceId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearDevice(String riderId) async {
    try {
      return await _collection.clearDevice(riderId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> adminForceLogout(String riderId) async {
    try {
      return await _collection.adminForceLogoutRider(riderId);
    } catch (e) {
      return false;
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final ridersProvider = StateNotifierProvider<RidersNotifier, RidersState>(
  (ref) => RidersNotifier(),
);

// Real-time stream for current rider's data
final riderStreamProvider = StreamProvider.family<RiderModel?, String>((
  ref,
  riderId,
) {
  return RidersCollection().getRiderStream(riderId);
});
