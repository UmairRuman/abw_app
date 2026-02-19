// lib/features/orders/data/models/order_model.dart
// UPDATED WITH MILESTONE 3 FIELDS

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
    super.estimatedDeliveryTime,
    super.statusHistory,
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

    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhone: json['userPhone'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      items: items,
      deliveryAddress: address,
      deliveryTimeSlot: json['deliveryTimeSlot'] as String,
      specialInstructions: json['specialInstructions'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
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

      // ✅ NEW MILESTONE 3 FIELDS
      riderPhone: json['riderPhone'] as String?,
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      storeCommission: (json['storeCommission'] as num?)?.toDouble(),

      estimatedDeliveryTime:
          json['estimatedDeliveryTime'] != null
              ? (json['estimatedDeliveryTime'] as Timestamp).toDate()
              : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      statusHistory: statusHistory,
    );
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

      // ✅ NEW MILESTONE 3 FIELDS
      'riderPhone': riderPhone,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'distance': distance,
      'storeCommission': storeCommission,

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
    DateTime? estimatedDeliveryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderStatusUpdate>? statusHistory,
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
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
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
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      note: json['note'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
      'updatedBy': updatedBy,
    };
  }
}
