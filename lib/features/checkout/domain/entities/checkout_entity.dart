// lib/features/checkout/domain/entities/checkout_entity.dart

import 'package:abw_app/features/addresses/data/models/address_model.dart';
import 'package:abw_app/features/cart/data/models/cart_item_model.dart';
import 'package:equatable/equatable.dart';

class CheckoutEntity extends Equatable {
  final String id;
  final String userId;
  final String storeId;
  final String storeName;
  final List<CartItemModel> items;
  final AddressModel deliveryAddress;
  final String deliveryTimeSlot; // 'ASAP', '30min', '1hour', '2hours'
  final String? specialInstructions;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;

  const CheckoutEntity({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.storeName,
    required this.items,
    required this.deliveryAddress,
    required this.deliveryTimeSlot,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    this.specialInstructions,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    storeId,
    storeName,
    items,
    deliveryAddress,
    deliveryTimeSlot,
    specialInstructions,
    subtotal,
    deliveryFee,
    total,
    createdAt,
  ];
}
