// lib/features/cart/data/models/cart_item_model.dart

import 'package:abw_app/features/products/domain/entities/product_variant.dart';

class CartItemModel {
  final String productId;
  final String productName;
  final String productImage;
  final String storeId;
  final String storeName;
  final double price;
  final int quantity;
  final double discountedPrice;
  final double total;
  final bool isAvailable;
  final int maxQuantity;
  final String unit;

  final ProductVariant? selectedVariant;
  final List<ProductAddon> selectedAddons;
  final String? specialInstructions;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.storeId,
    required this.storeName,
    required this.price,
    required this.quantity,
    required this.discountedPrice,
    required this.total,
    required this.maxQuantity,
    required this.unit,
    this.isAvailable = true,
    this.selectedVariant,
    this.selectedAddons = const [],
    this.specialInstructions,
  });

  /// ✅ FIXED: calculateTotal now includes variant extra + addons extra.
  /// discountedPrice here is the base product discounted price (before variant).
  double calculateTotal() {
    final double variantExtra = selectedVariant?.price ?? 0.0;
    final double addonsExtra = selectedAddons.fold(
      0.0,
      (sum, a) => sum + a.price,
    );
    return (discountedPrice + variantExtra + addonsExtra) * quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'storeId': storeId,
      'storeName': storeName,
      'price': price,
      'quantity': quantity,
      'discountedPrice': discountedPrice,
      'total': total,
      'isAvailable': isAvailable,
      'maxQuantity': maxQuantity,
      'unit': unit,
      'selectedVariant': selectedVariant?.toJson(),
      'selectedAddons': selectedAddons.map((a) => a.toJson()).toList(),
      'specialInstructions': specialInstructions,
    };
  }

  // ✅ FIXED: fromJson now correctly deserializes selectedVariant,
  // selectedAddons, and specialInstructions — they were declared above
  // but never assigned in the return statement before.
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    ProductVariant? selectedVariant;
    if (json['selectedVariant'] != null) {
      selectedVariant = ProductVariant.fromJson(
        json['selectedVariant'] as Map<String, dynamic>,
      );
    }

    final addonsList = json['selectedAddons'] as List? ?? [];
    final selectedAddons =
        addonsList
            .map((a) => ProductAddon.fromJson(a as Map<String, dynamic>))
            .toList();

    return CartItemModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      discountedPrice: (json['discountedPrice'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      maxQuantity: json['maxQuantity'] as int,
      unit: json['unit'] as String,
      // ✅ These three were missing from the return before:
      selectedVariant: selectedVariant,
      selectedAddons: selectedAddons,
      specialInstructions: json['specialInstructions'] as String?,
    );
  }

  // ✅ FIXED: copyWith now includes selectedVariant, selectedAddons,
  // and specialInstructions so cart updates preserve customizations.
  CartItemModel copyWith({
    String? productId,
    String? productName,
    String? productImage,
    String? storeId,
    String? storeName,
    double? price,
    int? quantity,
    double? discountedPrice,
    double? total,
    bool? isAvailable,
    int? maxQuantity,
    String? unit,
    ProductVariant? selectedVariant, // ✅ was missing
    List<ProductAddon>? selectedAddons, // ✅ was missing
    String? specialInstructions, // ✅ was missing
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      total: total ?? this.total,
      isAvailable: isAvailable ?? this.isAvailable,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      unit: unit ?? this.unit,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  @override
  String toString() {
    return 'CartItemModel(productId: $productId, name: $productName, '
        'variant: ${selectedVariant?.name}, qty: $quantity, total: $total)';
  }
}
