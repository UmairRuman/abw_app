// lib/features/checkout/domain/entities/checkout_entity.dart

import 'package:equatable/equatable.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../addresses/domain/entities/address_entity.dart';

class CheckoutEntity extends Equatable {
  final String id;
  final String userId;
  final String storeId;
  final String storeName;
  final List<CartItemEntity> items;
  final AddressEntity deliveryAddress;
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
    this.specialInstructions,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
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
