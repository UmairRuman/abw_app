// lib/features/orders/data/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_entity.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../addresses/data/models/address_model.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userPhone,
    required super.storeId,
    required super.storeName,
    required super.items,
    required super.deliveryAddress,
    required super.deliveryTimeSlot,
    required super.subtotal,
    required super.deliveryFee,
    required super.total,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.specialInstructions,
    super.discount,
    super.paymentProofUrl,
    super.paymentTransactionId,
    super.riderId,
    super.riderName,
    super.riderPhone,
    super.pickupLatitude,
    super.pickupLongitude,
    super.deliveryLatitude,
    super.deliveryLongitude,
    super.distance,
    super.storeCommission,
    super.cancellationReason,
    super.cancelledAt,
    super.cancelledBy,
    super.riderRefusalReason,
    super.riderRefusedAt,
    super.estimatedDeliveryTime,
    super.statusHistory,
    super.cashCheckedIn,
    super.cashCheckedInAt,
    super.cashCheckedInAmount,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    final items =
        itemsList
            .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
            .toList();

    final addressMap = json['deliveryAddress'] as Map<String, dynamic>;
    final address = AddressModel.fromJson(addressMap);

    final historyList = json['statusHistory'] as List? ?? [];
    final statusHistory =
        historyList
            .map(
              (h) => OrderStatusUpdateModel.fromJson(h as Map<String, dynamic>),
            )
            .toList();

    final deliveryLat =
        (json['deliveryLatitude'] as num?)?.toDouble() ??
        (address.latitude != 0.0 ? address.latitude : null);
    final deliveryLng =
        (json['deliveryLongitude'] as num?)?.toDouble() ??
        (address.longitude != 0.0 ? address.longitude : null);

    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String? ?? '',
      items: items,
      deliveryAddress: address,
      deliveryTimeSlot: json['deliveryTimeSlot'] as String? ?? 'ASAP',
      specialInstructions: json['specialInstructions'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cod,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentProofUrl: json['paymentProofUrl'] as String?,
      paymentTransactionId: json['paymentTransactionId'] as String?,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      riderId: json['riderId'] as String?,
      riderName: json['riderName'] as String?,
      riderPhone: json['riderPhone'] as String?,
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      deliveryLatitude: deliveryLat,
      deliveryLongitude: deliveryLng,
      distance: (json['distance'] as num?)?.toDouble(),
      storeCommission: (json['storeCommission'] as num?)?.toDouble(),
      cancellationReason: json['cancellationReason'] as String?,
      cancelledBy: json['cancelledBy'] as String?,
      riderRefusalReason: json['riderRefusalReason'] as String?,

      // ✅ ALL Timestamp fields use _parseTimestamp — safe for null pending-writes
      cancelledAt: _parseTimestamp(json['cancelledAt']),
      riderRefusedAt: _parseTimestamp(json['riderRefusedAt']),
      estimatedDeliveryTime: _parseTimestamp(json['estimatedDeliveryTime']),
      createdAt: _parseTimestamp(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(json['updatedAt']) ?? DateTime.now(),
      cashCheckedInAt: _parseTimestamp(json['cashCheckedInAt']),

      statusHistory: statusHistory,
      cashCheckedIn: json['cashCheckedIn'] as bool?,
      cashCheckedInAmount: (json['cashCheckedInAmount'] as num?)?.toDouble(),
    );
  }

  /// ✅ Null-safe Timestamp parser.
  /// Returns null for nullable fields; call ?? DateTime.now() for required ones.
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'storeId': storeId,
      'storeName': storeName,
      'items': items.map((item) => (item).toJson()).toList(),
      'deliveryAddress': (deliveryAddress).toJson(),
      'deliveryTimeSlot': deliveryTimeSlot,
      'specialInstructions': specialInstructions,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus.name,
      'paymentProofUrl': paymentProofUrl,
      'paymentTransactionId': paymentTransactionId,
      'status': status.name,
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'distance': distance,
      'storeCommission': storeCommission,
      'cancellationReason': cancellationReason,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelledBy': cancelledBy,
      'riderRefusalReason': riderRefusalReason,
      'riderRefusedAt':
          riderRefusedAt != null ? Timestamp.fromDate(riderRefusedAt!) : null,
      'estimatedDeliveryTime':
          estimatedDeliveryTime != null
              ? Timestamp.fromDate(estimatedDeliveryTime!)
              : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'statusHistory':
          statusHistory
              .map((h) => (h as OrderStatusUpdateModel).toJson())
              .toList(),
      'cashCheckedIn': cashCheckedIn,
      'cashCheckedInAt':
          cashCheckedInAt != null ? Timestamp.fromDate(cashCheckedInAt!) : null,
      'cashCheckedInAmount': cashCheckedInAmount,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? storeId,
    String? storeName,
    List<CartItemModel>? items,
    AddressModel? deliveryAddress,
    String? deliveryTimeSlot,
    String? specialInstructions,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? paymentProofUrl,
    String? paymentTransactionId,
    OrderStatus? status,
    String? riderId,
    String? riderName,
    String? riderPhone,
    double? pickupLatitude,
    double? pickupLongitude,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? distance,
    double? storeCommission,
    String? cancellationReason,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? riderRefusalReason,
    DateTime? riderRefusedAt,
    DateTime? estimatedDeliveryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderStatusUpdate>? statusHistory,
    bool? cashCheckedIn,
    DateTime? cashCheckedInAt,
    double? cashCheckedInAmount,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryTimeSlot: deliveryTimeSlot ?? this.deliveryTimeSlot,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      status: status ?? this.status,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      distance: distance ?? this.distance,
      storeCommission: storeCommission ?? this.storeCommission,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      riderRefusalReason: riderRefusalReason ?? this.riderRefusalReason,
      riderRefusedAt: riderRefusedAt ?? this.riderRefusedAt,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
      cashCheckedIn: cashCheckedIn ?? this.cashCheckedIn,
      cashCheckedInAt: cashCheckedInAt ?? this.cashCheckedInAt,
      cashCheckedInAmount: cashCheckedInAmount ?? this.cashCheckedInAmount,
    );
  }
}

class OrderStatusUpdateModel extends OrderStatusUpdate {
  const OrderStatusUpdateModel({
    required super.status,
    required super.timestamp,
    super.note,
    super.updatedBy,
  });

  factory OrderStatusUpdateModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusUpdateModel(
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      // ✅ Safe: handles null, Timestamp, DateTime, String, int
      timestamp: _parseTimestamp(json['timestamp']),
      note: json['note'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now(); // null → now
    if (value is Timestamp) return value.toDate(); // Firestore Timestamp
    if (value is DateTime) return value; // already DateTime
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now(); // ISO string
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value); // epoch ms
    }
    return DateTime.now(); // fallback
  }

  static OrderStatus _parseStatus(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp), // ✅ Safe inside arrayUnion
      'note': note,
      'updatedBy': updatedBy,
    };
  }
}
