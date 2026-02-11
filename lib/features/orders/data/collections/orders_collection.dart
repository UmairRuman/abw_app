// lib/features/orders/data/collections/orders_collection.dart

import 'package:abw_app/features/orders/domain/entities/order_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrdersCollection {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'orders';

  // Create order
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

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc =
          await _firestore.collection(_collectionPath).doc(orderId).get();
      if (doc.exists && doc.data() != null) {
        return OrderModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Get user orders
  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Get orders by date range (for history - last 5 days)
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
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Get all orders (admin)
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Update order status
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

  // Assign rider to order
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

  // Update payment proof
  Future<bool> updatePaymentProof(String orderId, String proofUrl) async {
    try {
      await _firestore.collection(_collectionPath).doc(orderId).update({
        'paymentProofUrl': proofUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating payment proof: $e');
      return false;
    }
  }

  // Cancel order (only if pending)
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      final doc =
          await _firestore.collection(_collectionPath).doc(orderId).get();
      if (doc.exists) {
        final order = OrderModel.fromJson(doc.data()!);

        // Only allow cancel if pending
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


  Stream<List<OrderModel>> getRiderOrders(String riderId) {
  return _firestore
      .collection(_collectionPath)
      .where('riderId', isEqualTo: riderId)
      .where('status', isEqualTo: OrderStatus.outForDelivery.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) =>
              OrderModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList());
}

// Get rider's delivered orders (last 5 days for earnings)
Stream<List<OrderModel>> getRiderDeliveredOrders(String riderId) {
  final startDate = DateTime.now().subtract(Duration(days: 5));
  return _firestore
      .collection(_collectionPath)
      .where('riderId', isEqualTo: riderId)
      .where('status', isEqualTo: OrderStatus.delivered.name)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) =>
              OrderModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList());
}

}
