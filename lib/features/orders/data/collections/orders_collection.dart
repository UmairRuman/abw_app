// lib/features/orders/data/collections/orders_collection.dart
// UPDATED: Filter cancelled from rider queries, added cashCheckIn

import 'package:abw_app/features/orders/domain/entities/order_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrdersCollection {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'orders';

  // ── Create / Read ────────────────────────────────────────────────────────

  Future<bool> createOrder(OrderModel order) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(order.id)
          .set(order.toJson());
      return true;
    } catch (e) {
      print('Error creating order: $e');
      return false;
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc =
          await _firestore.collection(_collectionPath).doc(orderId).get();
      if (doc.exists && doc.data() != null) {
        return OrderModel.fromJson({'id': doc.id, ...doc.data()!});
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // ── Customer Streams ─────────────────────────────────────────────────────

  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => OrderModel.fromJson({'id': doc.id, ...doc.data()}),
                  )
                  .toList(),
        );
  }

  Stream<List<OrderModel>> getUserOrdersByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => OrderModel.fromJson({'id': doc.id, ...doc.data()}),
                  )
                  .toList(),
        );
  }

  // ── Admin Stream ─────────────────────────────────────────────────────────

  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => OrderModel.fromJson({'id': doc.id, ...doc.data()}),
                  )
                  .toList(),
        );
  }

  // ── Rider Streams ────────────────────────────────────────────────────────

  /// ✅ FIX #1: Returns only ACTIVE (outForDelivery) orders for a rider.
  /// Cancelled orders are excluded both by status query AND client-side filter
  /// (double safety, in case cancelledBy field update races with status update).
  Stream<List<OrderModel>> getRiderOrders(String riderId) {
    // ✅ Return ALL active statuses — rider needs to see and progress all of them
    return _firestore
        .collection(_collectionPath)
        .where('riderId', isEqualTo: riderId)
        .where(
          'status',
          whereIn: [
            OrderStatus.confirmed.name,
            OrderStatus.preparing.name,
            OrderStatus.outForDelivery.name,
          ],
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => OrderModel.fromJson({'id': doc.id, ...doc.data()}),
                  )
                  .where((order) => order.cancelledBy == null)
                  .toList(),
        );
  }

  /// Returns delivered orders for rider analytics (last 30 days)
  Stream<List<OrderModel>> getRiderDeliveredOrders(String riderId) {
    final startDate = DateTime.now().subtract(const Duration(days: 30));
    return _firestore
        .collection(_collectionPath)
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: OrderStatus.delivered.name)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => OrderModel.fromJson({'id': doc.id, ...doc.data()}),
                  )
                  .toList(),
        );
  }

  // ── Status Updates ───────────────────────────────────────────────────────

  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
    String? note,
    String? updatedBy,
  ) async {
    try {
      final statusUpdate = OrderStatusUpdateModel(
        status: newStatus,
        timestamp: DateTime.now(),
        note: note,
        updatedBy: updatedBy,
      );

      await _firestore.collection(_collectionPath).doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([statusUpdate.toJson()]),
      });
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  Future<bool> updatePaymentStatus(
    String orderId,
    PaymentStatus newStatus,
  ) async {
    try {
      await _firestore.collection(_collectionPath).doc(orderId).update({
        'paymentStatus': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating payment status: $e');
      return false;
    }
  }

  // ── Cash Check-In ────────────────────────────────────────────────────────

  /// ✅ NEW: Rider physically received cash from customer.
  /// Marks the order and updates rider's totalCollectedCash in Firestore.
  Future<bool> cashCheckIn(
    String orderId,
    String riderId,
    double amount,
  ) async {
    try {
      // Mark order as cash received
      await _firestore.collection(_collectionPath).doc(orderId).update({
        'cashCheckedIn': true,
        'cashCheckedInAt': FieldValue.serverTimestamp(),
        'cashCheckedInAmount': amount,
        'cashCheckedInBy': riderId,
      });

      // Update rider's cash totals (rider is in 'users' collection)
      await _firestore.collection('users').doc(riderId).update({
        'totalCollectedCash': FieldValue.increment(amount),
        'todayCollectedCash': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      print('Error on cash check-in: $e');
      return false;
    }
  }

  // ── Assign / Cancel ──────────────────────────────────────────────────────

  Future<bool> assignRider(
    String orderId,
    String riderId,
    String riderName,
  ) async {
    try {
      await _firestore.collection(_collectionPath).doc(orderId).update({
        'riderId': riderId,
        'riderName': riderName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error assigning rider: $e');
      return false;
    }
  }

  Future<bool> updatePaymentProof(String orderId, String proofUrl) async {
    try {
      await _firestore.collection(_collectionPath).doc(orderId).update({
        'paymentProofUrl': proofUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      final doc =
          await _firestore.collection(_collectionPath).doc(orderId).get();
      if (doc.exists) {
        final order = OrderModel.fromJson({'id': doc.id, ...doc.data()!});
        if (order.status == OrderStatus.pending) {
          final statusUpdate = OrderStatusUpdateModel(
            status: OrderStatus.cancelled,
            timestamp: DateTime.now(),
            note: reason,
          );
          await _firestore.collection(_collectionPath).doc(orderId).update({
            'status': OrderStatus.cancelled.name,
            'updatedAt': FieldValue.serverTimestamp(),
            'statusHistory': FieldValue.arrayUnion([statusUpdate.toJson()]),
          });
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }
}
