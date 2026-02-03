// lib/features/cart/data/models/cart_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';

class CartModel {
  final String userId;
  final List<CartItemModel> items;
  final int totalItems;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? storeId;
  final String? storeName;
  final DateTime updatedAt;

  CartModel({
    required this.userId,
    this.items = const [],
    this.totalItems = 0,
    this.subtotal = 0.0,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.storeId,
    this.storeName,
    required this.updatedAt,
  });

  /// Calculate subtotal from items
  double calculateSubtotal() {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  /// Calculate total (subtotal + delivery - discount)
  double calculateTotal() {
    return subtotal + deliveryFee - discount;
  }

  /// Get total item count
  int getItemCount() {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalItems': totalItems,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'storeId': storeId,
      'storeName': storeName,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    
    return CartModel(
      userId: json['userId'] as String,
      items: itemsList
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalItems: json['totalItems'] as int? ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      storeId: json['storeId'] as String?,
      storeName: json['storeName'] as String?,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  CartModel copyWith({
    String? userId,
    List<CartItemModel>? items,
    int? totalItems,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    String? storeId,
    String? storeName,
    DateTime? updatedAt,
  }) {
    return CartModel(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalItems: totalItems ?? this.totalItems,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create empty cart
  factory CartModel.empty(String userId) {
    return CartModel(
      userId: userId,
      items: [],
      totalItems: 0,
      subtotal: 0.0,
      deliveryFee: 0.0,
      discount: 0.0,
      total: 0.0,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CartModel(userId: $userId, items: ${items.length}, total: $total)';
  }
}