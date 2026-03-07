// lib/features/orders/presentation/providers/orders_provider.dart

import 'dart:developer';

import 'package:abw_app/core/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/orders_collection.dart';
import '../../data/models/order_model.dart';
import '../../domain/entities/order_entity.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../addresses/data/models/address_model.dart';
import '../../../cart/data/models/cart_item_model.dart';

// Orders State
abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<OrderModel> orders;
  OrdersLoaded(this.orders);
}

class OrderSingleLoaded extends OrdersState {
  final OrderModel order;
  OrderSingleLoaded(this.order);
}

class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
}

// Orders Notifier
class OrdersNotifier extends StateNotifier<OrdersState> {
  final Ref ref;
  final OrdersCollection _collection = OrdersCollection();
  final _firestore = FirebaseFirestore.instance;

  OrdersNotifier(this.ref) : super(OrdersInitial());

  // Update payment status
  Future<bool> updatePaymentStatus(
    String orderId,
    PaymentStatus newStatus,
  ) async {
    try {
      await _collection.updatePaymentStatus(orderId, newStatus);
      return true;
    } catch (e) {
      print('Error updating payment status: $e');
      return false;
    }
  }

  // Place Order
  Future<String?> placeOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required PaymentMethod paymentMethod,
    String? paymentProofUrl,
  }) async {
    try {
      final checkoutState = ref.read(checkoutProvider);
      if (checkoutState is! CheckoutLoaded) {
        throw Exception('Checkout data not available');
      }

      final checkout = checkoutState.checkout;

      // Calculate estimated delivery time
      final estimatedDeliveryTime =
          ref.read(checkoutProvider.notifier).calculateEstimatedDeliveryTime();

      // Create order ID
      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      // Initial status update
      final initialStatus = OrderStatusUpdateModel(
        status: OrderStatus.pending,
        timestamp: DateTime.now(),
        note: 'Order placed',
      );

      // Create order
      final order = OrderModel(
        id: orderId,
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        storeId: checkout.storeId,
        storeName: checkout.storeName,
        items: checkout.items,
        deliveryAddress: checkout.deliveryAddress,
        deliveryTimeSlot: 'ASAP', // Placeholder
        specialInstructions: checkout.specialInstructions,
        subtotal: checkout.subtotal,
        deliveryFee: checkout.deliveryFee,
        discount: 0,
        total: checkout.total,
        paymentMethod: paymentMethod,
        paymentStatus:
            paymentMethod == PaymentMethod.cod
                ? PaymentStatus.pending
                : PaymentStatus.pending, // Will be verified by admin
        paymentProofUrl: paymentProofUrl,
        paymentTransactionId: null,
        status: OrderStatus.pending,
        riderId: null,
        riderName: null,
        estimatedDeliveryTime: estimatedDeliveryTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        statusHistory: [initialStatus],
      );

      // Save to Firestore
      final success = await _collection.createOrder(order);

      if (success) {
        // Clear cart
        await ref.read(cartProvider.notifier).clearCart(userId);

        return orderId;
      }

      return null;
    } catch (e) {
      print('Error placing order: $e');
      return null;
    }
  }

  // Get order by ID
  Future<void> getOrderById(String orderId) async {
    state = OrdersLoading();

    try {
      final order = await _collection.getOrderById(orderId);

      if (order != null) {
        state = OrderSingleLoaded(order);
      } else {
        state = OrdersError('Order not found');
      }
    } catch (e) {
      state = OrdersError(e.toString());
    }
  }

  // Get user orders (stream)
  Stream<List<OrderModel>> getUserOrdersStream(String userId) {
    return _collection.getUserOrders(userId);
  }

  // Get user orders by date range (last 5 days)
  Stream<List<OrderModel>> getUserOrderHistory(String userId) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 5));
    return _collection.getUserOrdersByDateRange(userId, startDate, endDate);
  }

  // Get all orders (admin)
  Stream<List<OrderModel>> getAllOrdersStream() {
    return _collection.getAllOrders();
  }

  // ✅ FIXED: Admin cancels order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      log('🚫 Admin cancelling order: $orderId');

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        log('❌ Order not found');
        return false;
      }

      final orderData = orderDoc.data()!;
      final customerId = orderData['userId'] as String;
      final riderId = orderData['riderId'] as String?;
      final customerName = orderData['userName'] as String;

      // Cancel the order
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'admin',
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'cancelled',
            'timestamp': FieldValue.serverTimestamp(),
            'note': 'Order cancelled by admin: $reason',
            'updatedBy': 'admin',
          },
        ]),
      });

      // ✅ FIX: If a rider was assigned, remove this order from their active list
      // and restore their status to available if no other orders remain.
      if (riderId != null) {
        await _firestore.collection('users').doc(riderId).update({
          'currentOrderIds': FieldValue.arrayRemove([orderId]),
          // Also clear legacy field if it matches
          'currentOrderId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Check if rider has other active orders
        final riderDoc =
            await _firestore.collection('users').doc(riderId).get();
        final remainingOrders = List<String>.from(
          List<String>.from(
            (riderDoc.data()?['currentOrderIds'] as List<dynamic>? ?? []),
          ),
        );
        if (remainingOrders.isEmpty) {
          await _firestore.collection('users').doc(riderId).update({
            'status': 'available',
          });
        }
      }

      // Notify customer
      await NotificationService.sendNotificationToUser(
        userId: customerId,
        title: '❌ Order Cancelled',
        body: 'Your order has been cancelled. Reason: $reason',
        data: {'type': 'order_cancelled', 'orderId': orderId, 'reason': reason},
      );

      // Notify rider if assigned
      if (riderId != null) {
        await NotificationService.sendNotificationToUser(
          userId: riderId,
          title: '❌ Order Cancelled',
          body: 'Order from $customerName has been cancelled by admin.',
          data: {
            'type': 'order_cancelled',
            'orderId': orderId,
            'reason': reason,
          },
        );
      }

      log('✅ Order cancelled and rider notified/updated');
      return true;
    } catch (e) {
      log('❌ Error cancelling order: $e');
      return false;
    }
  }

  // ✅ FIXED: Rider refuses order - status goes back to "confirmed" (not "ready")
  Future<bool> refuseOrderByRider(String orderId, String reason) async {
    try {
      log('🚫 Rider refusing order: $orderId');
      log('   Reason: $reason');

      // Get order first
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        log('❌ Order not found');
        return false;
      }

      final orderData = orderDoc.data()!;
      final customerId = orderData['userId'] as String;
      final customerName = orderData['userName'] as String;
      final riderName = orderData['riderName'] as String?;
      final total = orderData['total'] as double;
      final paymentMethod = orderData['paymentMethod'] as String;
      final paymentProofUrl = orderData['paymentProofUrl'] as String?;

      // ✅ FIXED: Unassign rider and set back to "confirmed" (not "ready")
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'confirmed', // ✅ CHANGED from 'ready' to 'confirmed'
        'riderId': null,
        'riderName': null,
        'riderPhone': null,
        'riderRefusalReason': reason, // ✅ NEW FIELD
        'riderRefusedAt': FieldValue.serverTimestamp(), // ✅ NEW FIELD
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'confirmed',
            'timestamp': FieldValue.serverTimestamp(),
            'note': 'Rider refused delivery: $reason. Order reassigned.',
            'updatedBy': 'rider',
          },
        ]),
      });

      log('✅ Order unassigned and set back to confirmed');

      // Notify customer
      await NotificationService.sendNotificationToUser(
        userId: customerId,
        title: '🔄 Delivery Reassignment',
        body: 'We\'re finding a new rider for your order.',
        data: {'type': 'rider_refused', 'orderId': orderId},
      );

      // Notify admins about reassignment
      await NotificationService.sendNewOrderNotificationToAdmin(
        orderId: orderId,
        customerName: customerName,
        total: total,
        paymentMethod: paymentMethod,
        paymentProofUrl: paymentProofUrl,
        isReassignment: true, // ✅ Flag for reassignment
        previousRider: riderName,
        refusalReason: reason,
      );

      log('✅ Order refused successfully');
      return true;
    } catch (e) {
      log('❌ Error refusing order: $e');
      return false;
    }
  }

  // ✅ NEW: Update order status with customer notification
  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
    String? note,
    String updatedBy, // 'admin', 'rider', 'customer'
  ) async {
    try {
      log('📝 Updating order $orderId to ${newStatus.name} by $updatedBy');

      // Get order details first
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        log('❌ Order not found');
        return false;
      }

      final orderData = orderDoc.data()!;
      final userId = orderData['userId'] as String;
      final storeName = orderData['storeName'] as String;

      // Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy, // Track who updated it
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': newStatus.name,
            'timestamp': Timestamp.now(),
            'note': note ?? 'Status updated to ${newStatus.name}',
            'updatedBy': updatedBy,
          },
        ]),
      });

      // ✅ SEND NOTIFICATIONS (only when admin confirms/updates)
      // DON'T send customer notifications when rider updates status

      if (updatedBy == 'admin') {
        // Admin confirmed order → Notify customer
        if (newStatus == OrderStatus.confirmed) {
          await NotificationService.sendNotificationToUser(
            userId: userId,
            title: '✅ Order Confirmed!',
            body:
                'Your order from $storeName has been confirmed. Preparing your food now!',
            data: {
              'type': 'order_confirmed',
              'orderId': orderId,
              'storeName': storeName,
            },
          );
          log('✅ Customer notification sent: order confirmed');
        }
        // Admin marked as preparing → Notify customer
        else if (newStatus == OrderStatus.preparing) {
          await NotificationService.sendNotificationToUser(
            userId: userId,
            title: '👨‍🍳 Preparing Your Order',
            body: '$storeName is preparing your order. It will be ready soon!',
            data: {
              'type': 'order_preparing',
              'orderId': orderId,
              'storeName': storeName,
            },
          );
          log('✅ Customer notification sent: order preparing');
        }
      }
      // Rider picked up order → Notify customer (optional)
      else if (updatedBy == 'rider' &&
          newStatus == OrderStatus.outForDelivery) {
        await NotificationService.sendNotificationToUser(
          userId: userId,
          title: '🚚 Order Out for Delivery!',
          body: 'Your order from $storeName is on its way!',
          data: {
            'type': 'order_out_for_delivery',
            'orderId': orderId,
            'storeName': storeName,
          },
        );
        log('✅ Customer notification sent: out for delivery');
      }
      // Order delivered → Notify customer (from rider or admin)
      else if (newStatus == OrderStatus.delivered) {
        await NotificationService.sendNotificationToUser(
          userId: userId,
          title: '🎉 Order Delivered!',
          body:
              'Your order has been delivered. Enjoy your meal from $storeName!',
          data: {
            'type': 'order_delivered',
            'orderId': orderId,
            'storeName': storeName,
          },
        );
        log('✅ Customer notification sent: order delivered');
      }

      log('✅ Order status updated successfully');
      return true;
    } catch (e) {
      log('❌ Error updating order status: $e');
      return false;
    }
  }

  // Assign rider (admin)
  /// Assign rider to order and send notification
  Future<bool> assignRider(
    String orderId,
    String riderId,
    String riderName,
  ) async {
    try {
      log('🚚 Assigning rider $riderName to order $orderId');

      // Get order details
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        log('❌ Order not found');
        return false;
      }

      final orderData = orderDoc.data()!;
      final storeName = orderData['storeName'] as String;
      final userName = orderData['userName'] as String;
      final deliveryAddress =
          orderData['deliveryAddress'] as Map<String, dynamic>;
      final deliveryFee = orderData['deliveryFee'] as double;

      // Get rider phone
      final riderDoc = await _firestore.collection('riders').doc(riderId).get();

      final riderPhone = riderDoc.data()?['phone'] as String? ?? '';

      // Update order with rider info
      await _firestore.collection('orders').doc(orderId).update({
        'riderId': riderId,
        'riderName': riderName,
        'riderPhone': riderPhone,
        'status': OrderStatus.outForDelivery.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': OrderStatus.outForDelivery.name,
            'timestamp': Timestamp.now(),
            'note': 'Assigned to $riderName',
          },
        ]),
      });

      // Update rider with current order
      await _firestore.collection('riders').doc(riderId).update({
        'currentOrderId': orderId,
        'status': 'busy',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final specialInstructions = orderData['specialInstructions'] as String?;

      // ✅ SEND NOTIFICATION TO RIDER
      final addressString =
          '${deliveryAddress['addressLine1']}, ${deliveryAddress['area']}, ${deliveryAddress['city']}';

      await NotificationService.sendOrderAssignedNotificationToRider(
        riderId: riderId,
        orderId: orderId,
        customerName: userName,
        storeName: storeName,
        specialInstructions: specialInstructions, // ✅ NEW
        deliveryAddress: addressString,
        deliveryFee: deliveryFee,
      );

      log('✅ Rider assigned and notified');
      return true;
    } catch (e) {
      log('❌ Error assigning rider: $e');
      return false;
    }
  }
}

// Provider
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>(
  (ref) => OrdersNotifier(ref),
);

// Stream provider for user orders
final userOrdersStreamProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, userId) {
      return ref.read(ordersProvider.notifier).getUserOrdersStream(userId);
    });

// Stream provider for order history (last 5 days)
final userOrderHistoryStreamProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, userId) {
      return ref.read(ordersProvider.notifier).getUserOrderHistory(userId);
    });

// Stream for rider's assigned orders
final riderAssignedOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, riderId) {
      return OrdersCollection().getRiderOrders(riderId);
    });

// Stream for rider's delivered orders (earnings history)
final riderDeliveredOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, riderId) {
      return OrdersCollection().getRiderDeliveredOrders(riderId);
    });
