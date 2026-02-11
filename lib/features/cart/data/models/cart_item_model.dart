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

  // ✅ ADD THESE for variant/addon support
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
    // ✅ ADD THESE
    this.selectedVariant,
    this.selectedAddons = const [],
    this.specialInstructions,
  });

  /// Calculate total for this item
  double calculateTotal() {
    final itemPrice = discountedPrice > 0 ? discountedPrice : price;
    return itemPrice * quantity;
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
      // ✅ ADD THESE
      'selectedVariant': selectedVariant?.toJson(),
      'selectedAddons': selectedAddons.map((a) => a.toJson()).toList(),
      'specialInstructions': specialInstructions,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // ✅ Parse selectedVariant
    ProductVariant? selectedVariant;
    if (json['selectedVariant'] != null) {
      selectedVariant = ProductVariant.fromJson(
        json['selectedVariant'] as Map<String, dynamic>,
      );
    }

    // ✅ Parse selectedAddons
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
    );
  }

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
    );
  }

  @override
  String toString() {
    return 'CartItemModel(productId: $productId, name: $productName, qty: $quantity, total: $total)';
  }
}
