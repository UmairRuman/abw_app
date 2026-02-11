// lib/features/checkout/data/models/checkout_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/checkout_entity.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../addresses/data/models/address_model.dart';

class CheckoutModel extends CheckoutEntity {
  const CheckoutModel({
    required super.id,
    required super.userId,
    required super.storeId,
    required super.storeName,
    required super.items,
    required super.deliveryAddress,
    required super.deliveryTimeSlot,
    required super.subtotal,
    required super.deliveryFee,
    required super.total,
    required super.createdAt,
    super.specialInstructions,
  });

  factory CheckoutModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    final items =
        itemsList
            .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
            .toList();

    final addressMap = json['deliveryAddress'] as Map<String, dynamic>;
    final address = AddressModel.fromJson(addressMap);

    return CheckoutModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      items: items,
      deliveryAddress: address,
      deliveryTimeSlot: json['deliveryTimeSlot'] as String,
      specialInstructions: json['specialInstructions'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'storeId': storeId,
      'storeName': storeName,
      'items': items.map((item) => (item).toJson()).toList(),
      'deliveryAddress': (deliveryAddress).toJson(),
      'deliveryTimeSlot': deliveryTimeSlot,
      'specialInstructions': specialInstructions,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CheckoutModel copyWith({
    String? id,
    String? userId,
    String? storeId,
    String? storeName,
    List<CartItemModel>? items,
    AddressModel? deliveryAddress,
    String? deliveryTimeSlot,
    String? specialInstructions,
    double? subtotal,
    double? deliveryFee,
    double? total,
    DateTime? createdAt,
  }) {
    return CheckoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryTimeSlot: deliveryTimeSlot ?? this.deliveryTimeSlot,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
