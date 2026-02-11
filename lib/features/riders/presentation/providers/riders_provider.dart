// lib/features/riders/presentation/providers/riders_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/riders_collection.dart';
import '../../data/models/rider_model.dart';
import '../../domain/entities/rider_entity.dart';
import '../../../orders/data/collections/orders_collection.dart';
import '../../../orders/domain/entities/order_entity.dart';

// States
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

// Notifier
class RidersNotifier extends StateNotifier<RidersState> {
  final RidersCollection _collection = RidersCollection();
  final OrdersCollection _ordersCollection = OrdersCollection();

  RidersNotifier() : super(RidersInitial());

  // Get available riders (for admin assign dialog)
  Future<void> getAvailableRiders() async {
    state = RidersLoading();
    try {
      final riders = await _collection.getAvailableRiders();
      state = RidersLoaded(riders);
    } catch (e) {
      state = RidersError(e.toString());
    }
  }

  // Get rider by ID
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

  // Toggle online/offline
  Future<bool> toggleAvailability(
      String riderId, RiderStatus newStatus) async {
    try {
      return await _collection.updateRiderStatus(riderId, newStatus);
    } catch (e) {
      return false;
    }
  }

  // Accept order
  Future<bool> acceptOrder(String riderId, String orderId) async {
    try {
      // Update rider's current order
      await _collection.updateCurrentOrder(riderId, orderId);

      // Update order status to outForDelivery
      await _ordersCollection.updateOrderStatus(
        orderId,
        OrderStatus.outForDelivery,
        'Rider accepted and picked up order',
        riderId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mark as delivered
  Future<bool> markDelivered(
      String riderId, String orderId, double deliveryFee) async {
    try {
      // Update order to delivered
      await _ordersCollection.updateOrderStatus(
        orderId,
        OrderStatus.delivered,
        'Order delivered successfully',
        riderId,
      );

      // Update rider earnings & clear current order
      await _collection.updateEarnings(riderId, deliveryFee);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Providers
final ridersProvider =
    StateNotifierProvider<RidersNotifier, RidersState>(
  (ref) => RidersNotifier(),
);

// Stream provider for current rider
final riderStreamProvider =
    StreamProvider.family<RiderModel?, String>((ref, riderId) {
  return RidersCollection().getRiderStream(riderId);
});