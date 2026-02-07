// lib/features/products/domain/entities/product_variant.dart

import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  final String id;
  final String name; // "Small", "Medium", "Large"
  final double price;
  final bool isAvailable;
  final int? sortOrder;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [id, name, price, isAvailable, sortOrder];
}

class ProductAddon extends Equatable {
  final String id;
  final String name; // "Extra Cheese", "Olives", etc.
  final double price;
  final bool isAvailable;
  final int? maxQuantity;

  const ProductAddon({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.maxQuantity = 1,
  });

  @override
  List<Object?> get props => [id, name, price, isAvailable, maxQuantity];
}
