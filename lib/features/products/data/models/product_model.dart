// lib/features/products/data/models/product_model.dart

import 'package:abw_app/features/products/domain/entities/product_variant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String storeId;
  final String storeName;
  final String categoryId;
  final String categoryName;

  // Basic info
  final String name;
  final String description;
  final String shortDescription;

  // Images
  final List<String> images;
  final String thumbnail;

  // Pricing
  final double price;
  final double originalPrice;
  final double discount;
  final double discountedPrice;

  // Inventory
  final String unit;
  final int quantity;
  final int minOrderQuantity;
  final int maxOrderQuantity;

  // Status
  final bool isAvailable;
  final bool isFeatured;
  final bool isPopular;
  final bool isVegetarian;
  final bool isVegan;
  final bool isSpicy;

  // Additional info
  final int preparationTime;
  final List<String> tags;
  final List<String> allergens;
  final List<String> ingredients;

  // Stats
  final double rating;
  final int totalReviews;
  final int totalSold;

  // Nutrition
  final Map<String, dynamic>? nutritionInfo;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  final bool hasVariants;
  final List<ProductVariant> variants;
  final List<ProductAddon> addons;
  final String? specialInstructions;

  ProductModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.images,
    required this.thumbnail,
    required this.price,
    this.originalPrice = 0.0,
    this.discount = 0.0,
    required this.discountedPrice,
    required this.unit,
    required this.quantity,
    this.minOrderQuantity = 1,
    this.maxOrderQuantity = 99,
    this.isAvailable = true,
    this.isFeatured = false,
    this.isPopular = false,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isSpicy = false,
    this.preparationTime = 0,
    this.tags = const [],
    this.allergens = const [],
    this.ingredients = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalSold = 0,
    this.nutritionInfo,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    // new parameters
    this.hasVariants = false,
    this.variants = const [],
    this.addons = const [],
    this.specialInstructions,
  });

  /// Calculate discounted price
  double calculateDiscountedPrice() {
    if (discount > 0) {
      return price - (price * discount / 100);
    }
    return price;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'storeName': storeName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'name': name,
      'description': description,
      'shortDescription': shortDescription,
      'images': images,
      'thumbnail': thumbnail,
      'price': price,
      'originalPrice': originalPrice,
      'discount': discount,
      'discountedPrice': discountedPrice,
      'unit': unit,
      'quantity': quantity,
      'minOrderQuantity': minOrderQuantity,
      'maxOrderQuantity': maxOrderQuantity,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'isPopular': isPopular,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isSpicy': isSpicy,
      'preparationTime': preparationTime,
      'tags': tags,
      'allergens': allergens,
      'ingredients': ingredients,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalSold': totalSold,
      'nutritionInfo': nutritionInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'hasVariants': hasVariants,
      'variants':
          variants
              .map(
                (v) => {
                  'id': v.id,
                  'name': v.name,
                  'price': v.price,
                  'isAvailable': v.isAvailable,
                  'sortOrder': v.sortOrder,
                },
              )
              .toList(),
      'addons':
          addons
              .map(
                (a) => {
                  'id': a.id,
                  'name': a.name,
                  'price': a.price,
                  'isAvailable': a.isAvailable,
                  'maxQuantity': a.maxQuantity,
                },
              )
              .toList(),
      'specialInstructions': specialInstructions,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse variants
    final variantsList = json['variants'] as List? ?? [];
    final variants =
        variantsList
            .map(
              (v) => ProductVariant(
                id: v['id'] as String,
                name: v['name'] as String,
                price: (v['price'] as num).toDouble(),
                isAvailable: v['isAvailable'] as bool? ?? true,
                sortOrder: v['sortOrder'] as int?,
              ),
            )
            .toList();

    // Parse addons
    final addonsList = json['addons'] as List? ?? [];
    final addons =
        addonsList
            .map(
              (a) => ProductAddon(
                id: a['id'] as String,
                name: a['name'] as String,
                price: (a['price'] as num).toDouble(),
                isAvailable: a['isAvailable'] as bool? ?? true,
                maxQuantity: a['maxQuantity'] as int? ?? 1,
              ),
            )
            .toList();

    return ProductModel(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      shortDescription: json['shortDescription'] as String,
      images: List<String>.from(json['images'] as List),
      thumbnail: json['thumbnail'] as String,
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (json['discountedPrice'] as num).toDouble(),
      unit: json['unit'] as String,
      quantity: json['quantity'] as int,
      minOrderQuantity: json['minOrderQuantity'] as int? ?? 1,
      maxOrderQuantity: json['maxOrderQuantity'] as int? ?? 99,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isPopular: json['isPopular'] as bool? ?? false,
      isVegetarian: json['isVegetarian'] as bool? ?? false,
      isVegan: json['isVegan'] as bool? ?? false,
      isSpicy: json['isSpicy'] as bool? ?? false,
      preparationTime: json['preparationTime'] as int? ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      allergens:
          json['allergens'] != null
              ? List<String>.from(json['allergens'] as List)
              : [],
      ingredients:
          json['ingredients'] != null
              ? List<String>.from(json['ingredients'] as List)
              : [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalSold: json['totalSold'] as int? ?? 0,
      nutritionInfo: json['nutritionInfo'] as Map<String, dynamic>?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      createdBy: json['createdBy'] as String,
      hasVariants: json['hasVariants'] as bool? ?? false,
      variants: variants,
      addons: addons,
      specialInstructions: json['specialInstructions'] as String?,
    );
  }

  ProductModel copyWith({
    String? id,
    String? storeId,
    String? storeName,
    String? categoryId,
    String? categoryName,
    String? name,
    String? description,
    String? shortDescription,
    List<String>? images,
    String? thumbnail,
    double? price,
    double? originalPrice,
    double? discount,
    double? discountedPrice,
    String? unit,
    int? quantity,
    int? minOrderQuantity,
    int? maxOrderQuantity,
    bool? isAvailable,
    bool? isFeatured,
    bool? isPopular,
    bool? isVegetarian,
    bool? isVegan,
    bool? isSpicy,
    int? preparationTime,
    List<String>? tags,
    List<String>? allergens,
    List<String>? ingredients,
    double? rating,
    int? totalReviews,
    int? totalSold,
    Map<String, dynamic>? nutritionInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ProductModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      images: images ?? this.images,
      thumbnail: thumbnail ?? this.thumbnail,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discount: discount ?? this.discount,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      maxOrderQuantity: maxOrderQuantity ?? this.maxOrderQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      isPopular: isPopular ?? this.isPopular,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isSpicy: isSpicy ?? this.isSpicy,
      preparationTime: preparationTime ?? this.preparationTime,
      tags: tags ?? this.tags,
      allergens: allergens ?? this.allergens,
      ingredients: ingredients ?? this.ingredients,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalSold: totalSold ?? this.totalSold,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory ProductModel.empty() {
    return ProductModel(
      id: '',
      storeId: '',
      storeName: '',
      categoryId: '',
      categoryName: '',
      name: '',
      description: '',
      shortDescription: '',
      images: [],
      thumbnail: '',
      price: 0.0,
      discountedPrice: 0.0,
      unit: '',
      quantity: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: '',
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, isAvailable: $isAvailable)';
  }
}
