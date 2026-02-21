// lib/features/auth/data/models/customer_model.dart
// FIXED VERSION - Better null handling

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/enums/user_role.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.profileImage,
    super.address,
    super.latitude,
    super.longitude,
    super.isPhoneVerified = false,
  });

  // ✅ FIXED: Better null handling
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['userId'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      // ✅ SAFE NULL HANDLING
      address: json['address'] as String?, // Can be null
      latitude: _parseDouble(json['latitude']), // Safe parsing
      longitude: _parseDouble(json['longitude']), // Safe parsing
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
    );
  }

  // ✅ SAFE DOUBLE PARSING
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'role': UserRole.customer.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'address': address, // Can be null
      'latitude': latitude, // Can be null
      'longitude': longitude, // Can be null
      'isPhoneVerified': isPhoneVerified,
    };
  }

  // From Entity
  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      phone: entity.phone,
      profileImage: entity.profileImage,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isPhoneVerified: entity.isPhoneVerified,
    );
  }

  // To Entity
  CustomerEntity toEntity() => this;

  // ✅ HELPER: Check if user has location
  bool get hasLocation => latitude != null && longitude != null;

  // ✅ HELPER: Get formatted location string
  String get locationString {
    if (!hasLocation) return 'No location set';
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }

  @override
  CustomerModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? address,
    double? latitude,
    double? longitude,
    bool? isPhoneVerified,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }
}
