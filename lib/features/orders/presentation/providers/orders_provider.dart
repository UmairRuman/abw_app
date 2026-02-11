// lib/features/orders/presentation/providers/orders_provider.dart

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
    final startDate = endDate.subtract(Duration(days: 5));
    return _collection.getUserOrdersByDateRange(userId, startDate, endDate);
  }

  // Get all orders (admin)
  Stream<List<OrderModel>> getAllOrdersStream() {
    return _collection.getAllOrders();
  }

  // Cancel order (only if pending)
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      return await _collection.cancelOrder(orderId, reason);
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }

  // Update order status (admin)
  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
    String? note,
    String? updatedBy,
  ) async {
    try {
      return await _collection.updateOrderStatus(
        orderId,
        newStatus,
        note,
        updatedBy,
      );
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // Assign rider (admin)
  Future<bool> assignRider(
    String orderId,
    String riderId,
    String riderName,
  ) async {
    try {
      return await _collection.assignRider(orderId, riderId, riderName);
    } catch (e) {
      print('Error assigning rider: $e');
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