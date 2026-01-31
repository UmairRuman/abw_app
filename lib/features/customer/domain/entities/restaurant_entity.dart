// lib/features/customer/domain/entities/restaurant_entity.dart

import 'package:equatable/equatable.dart';

class RestaurantEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final double rating;
  final int totalReviews;
  final String address;
  final double latitude;
  final double longitude;
  final int deliveryTime; // in minutes
  final double deliveryFee;
  final double minimumOrder;
  final bool isOpen;
  final bool isFeatured;
  final List<String> cuisines;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RestaurantEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.totalReviews,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minimumOrder,
    required this.isOpen,
    this.isFeatured = false,
    this.cuisines = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        category,
        rating,
        totalReviews,
        address,
        latitude,
        longitude,
        deliveryTime,
        deliveryFee,
        minimumOrder,
        isOpen,
        isFeatured,
        cuisines,
        createdAt,
        updatedAt,
      ];

  RestaurantEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? category,
    double? rating,
    int? totalReviews,
    String? address,
    double? latitude,
    double? longitude,
    int? deliveryTime,
    double? deliveryFee,
    double? minimumOrder,
    bool? isOpen,
    bool? isFeatured,
    List<String>? cuisines,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      isOpen: isOpen ?? this.isOpen,
      isFeatured: isFeatured ?? this.isFeatured,
      cuisines: cuisines ?? this.cuisines,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}