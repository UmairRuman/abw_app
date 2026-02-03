// lib/features/addresses/data/models/address_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String userId;
  final String label;
  final String name;
  final String phone;
  
  // Address details
  final String addressLine1;
  final String? addressLine2;
  final String area;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  
  // Coordinates
  final double latitude;
  final double longitude;
  
  // Status
  final bool isDefault;
  final String addressType;
  
  // Additional info
  final String? landmark;
  final String? deliveryInstructions;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.area,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    this.addressType = 'home',
    this.landmark,
    this.deliveryInstructions,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get full formatted address
  String getFullAddress() {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      area,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  /// Get short address for list view
  String getShortAddress() {
    return '$addressLine1, $area, $city';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'name': name,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'area': area,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'addressType': addressType,
      'landmark': landmark,
      'deliveryInstructions': deliveryInstructions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      label: json['label'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String?,
      area: json['area'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postalCode'] as String,
      country: json['country'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
      addressType: json['addressType'] as String? ?? 'home',
      landmark: json['landmark'] as String?,
      deliveryInstructions: json['deliveryInstructions'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? name,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? area,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    bool? isDefault,
    String? addressType,
    String? landmark,
    String? deliveryInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      addressType: addressType ?? this.addressType,
      landmark: landmark ?? this.landmark,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AddressModel.empty(String userId) {
    return AddressModel(
      id: '',
      userId: userId,
      label: '',
      name: '',
      phone: '',
      addressLine1: '',
      area: '',
      city: '',
      state: '',
      postalCode: '',
      country: 'Pakistan',
      latitude: 0.0,
      longitude: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AddressModel(id: $id, label: $label, isDefault: $isDefault)';
  }
}