// lib/features/auth/data/models/customer_model.dart
// UPDATED: Added FCM token fields

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
    super.fcmToken, // ✅ NEW
    super.fcmTokenUpdatedAt, // ✅ NEW
    super.address,
    super.latitude,
    super.longitude,
    super.isPhoneVerified = false,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id:
          (json['id'] ?? json['userId'])
              as String, // ✅ Handle both userId and id
      email:
          _parseString(json['email']) ??
          'no-email@example.com', // ✅ Safe default
      name: _parseString(json['name']) ?? 'Unknown User', // ✅ Safe default
      phone: _parseString(json['phone']) ?? '', // ✅ Safe default
      profileImage: _parseString(json['profileImage']), // ✅ Nullable
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      fcmToken: _parseString(json['fcmToken']), // ✅ Nullable
      fcmTokenUpdatedAt: _parseTimestamp(
        json['fcmTokenUpdatedAt'],
      ), // ✅ Nullable
      address: _parseString(
        json['address'],
      ), // ✅ Nullable - handles null for old users
      latitude: _parseDouble(json['latitude']), // ✅ Already safe
      longitude: _parseDouble(json['longitude']), // ✅ Already safe
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
    );
  }

  // ✅ ADD THIS NEW HELPER METHOD (add after _parseDouble)
  static String? _parseString(dynamic value, {String? fallback}) {
    if (value == null) return fallback;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  // Keep existing _parseDouble method
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ✅ UPDATE _parseTimestamp to handle nulls better
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
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
      'fcmToken': fcmToken, // ✅ NEW
      'fcmTokenUpdatedAt':
          fcmTokenUpdatedAt !=
                  null // ✅ NEW
              ? Timestamp.fromDate(fcmTokenUpdatedAt!)
              : null,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
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
      fcmToken: entity.fcmToken, // ✅ NEW
      fcmTokenUpdatedAt: entity.fcmTokenUpdatedAt, // ✅ NEW
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
    String? fcmToken, // ✅ NEW
    DateTime? fcmTokenUpdatedAt, // ✅ NEW
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
      fcmToken: fcmToken ?? this.fcmToken, // ✅ NEW
      fcmTokenUpdatedAt: fcmTokenUpdatedAt ?? this.fcmTokenUpdatedAt, // ✅ NEW
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }
}
