// lib/features/orders/domain/entities/order_entity.dart
// UPDATED: Added cancellation and rider refusal fields

import 'package:abw_app/features/addresses/data/models/address_model.dart';
import 'package:abw_app/features/cart/data/models/cart_item_model.dart';
import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

enum PaymentMethod { cod, jazzcash, easypaisa, bankTransfer }

enum PaymentStatus { pending, completed, failed }

class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String storeId;
  final String storeName;
  final List<CartItemModel> items;
  final AddressModel deliveryAddress;
  final String deliveryTimeSlot;
  final String? specialInstructions;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? paymentProofUrl;
  final String? paymentTransactionId;
  final OrderStatus status;
  final String? riderId;
  final String? riderName;

  // Milestone 3 fields
  final String? riderPhone;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? distance;
  final double? storeCommission;

  // ✅ NEW: Cancellation fields
  final String? cancellationReason; // Why order was cancelled
  final DateTime? cancelledAt; // When it was cancelled
  final String? cancelledBy; // Who cancelled: 'admin', 'customer', 'system'

  // ✅ NEW: Rider refusal fields
  final String? riderRefusalReason; // Why rider refused
  final DateTime? riderRefusedAt; // When rider refused

  final DateTime? estimatedDeliveryTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderStatusUpdate> statusHistory;

  final bool? cashCheckedIn; // true when rider has checked in cash
  final DateTime? cashCheckedInAt; // timestamp of check-in
  final double? cashCheckedInAmount;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.storeId,
    required this.storeName,
    required this.items,
    required this.deliveryAddress,
    required this.deliveryTimeSlot,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.specialInstructions,
    this.discount = 0,
    this.paymentProofUrl,
    this.paymentTransactionId,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.distance,
    this.storeCommission,
    // ✅ NEW: Cancellation fields (all nullable)
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledBy,
    // ✅ NEW: Rider refusal fields (all nullable)
    this.riderRefusalReason,
    this.riderRefusedAt,
    this.estimatedDeliveryTime,
    this.statusHistory = const [],
    this.cashCheckedIn,
    this.cashCheckedInAt,
    this.cashCheckedInAmount,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userPhone,
    storeId,
    storeName,
    items,
    deliveryAddress,
    deliveryTimeSlot,
    specialInstructions,
    subtotal,
    deliveryFee,
    discount,
    total,
    paymentMethod,
    paymentStatus,
    paymentProofUrl,
    paymentTransactionId,
    status,
    riderId,
    riderName,
    riderPhone,
    pickupLatitude,
    pickupLongitude,
    deliveryLatitude,
    deliveryLongitude,
    distance,
    storeCommission,
    cancellationReason, // ✅ NEW
    cancelledAt, // ✅ NEW
    cancelledBy, // ✅ NEW
    riderRefusalReason, // ✅ NEW
    riderRefusedAt, // ✅ NEW
    estimatedDeliveryTime,
    createdAt,
    updatedAt,
    statusHistory,
    cashCheckedIn,
    cashCheckedInAt,
    cashCheckedInAmount,
  ];
}

class OrderStatusUpdate extends Equatable {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;
  final String? updatedBy;

  const OrderStatusUpdate({
    required this.status,
    required this.timestamp,
    this.note,
    this.updatedBy,
  });

  @override
  List<Object?> get props => [status, timestamp, note, updatedBy];
}
