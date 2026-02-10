// lib/features/products/domain/entities/product_variant.dart

import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  final String id;
  final String name;
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

  // ✅ ADD fromJson
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int?,
    );
  }

  // ✅ ADD toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
      'sortOrder': sortOrder,
    };
  }

  // ✅ ADD copyWith (useful for state updates)
  ProductVariant copyWith({
    String? id,
    String? name,
    double? price,
    bool? isAvailable,
    int? sortOrder,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [id, name, price, isAvailable, sortOrder];
}

class ProductAddon extends Equatable {
  final String id;
  final String name;
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

  // ✅ ADD fromJson
  factory ProductAddon.fromJson(Map<String, dynamic> json) {
    return ProductAddon(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      maxQuantity: json['maxQuantity'] as int? ?? 1,
    );
  }

  // ✅ ADD toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
      'maxQuantity': maxQuantity,
    };
  }

  // ✅ ADD copyWith
  ProductAddon copyWith({
    String? id,
    String? name,
    double? price,
    bool? isAvailable,
    int? maxQuantity,
  }) {
    return ProductAddon(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      maxQuantity: maxQuantity ?? this.maxQuantity,
    );
  }

  @override
  List<Object?> get props => [id, name, price, isAvailable, maxQuantity];
}
