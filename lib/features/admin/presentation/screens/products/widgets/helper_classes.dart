// ✅ ADD THESE HELPER CLASSES

import 'package:abw_app/features/products/domain/entities/product_variant.dart';

class ProductVariantInput {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;
  final int sortOrder;

  ProductVariantInput({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.sortOrder,
  });

  factory ProductVariantInput.fromVariant(ProductVariant variant) {
    return ProductVariantInput(
      id: variant.id,
      name: variant.name,
      price: variant.price,
      isAvailable: variant.isAvailable,
      sortOrder: variant.sortOrder ?? 0,
    );
  }
}

class ProductAddonInput {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;
  final int maxQuantity;

  ProductAddonInput({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.maxQuantity,
  });

  factory ProductAddonInput.fromAddon(ProductAddon addon) {
    return ProductAddonInput(
      id: addon.id,
      name: addon.name,
      price: addon.price,
      isAvailable: addon.isAvailable,
      maxQuantity: addon.maxQuantity ?? 1,
    );
  }
}
