// lib/features/auth/data/models/rider_model.dart
// UPDATED: Multi-order, analytics, device lock + backward-compat migration

import 'package:abw_app/shared/enums/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/rider_entity.dart';

class RiderModel extends RiderEntity {
  const RiderModel({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.vehicleType,
    required super.vehicleNumber,
    super.fcmToken,
    super.fcmTokenUpdatedAt,
    super.role = UserRole.rider,
    super.profileImage,
    super.licenseNumber,
    super.isApproved = false,
    super.isAvailable = false,
    super.rating = 0.0,
    super.totalDeliveries = 0,
    super.approvedAt,
    super.approvedBy,
    super.status = RiderStatus.offline,
    super.totalEarnings = 0.0,
    super.currentOrderIds = const [],
    super.totalCollectedCash = 0.0,
    super.totalDistance = 0.0,
    super.todayDeliveries = 0,
    super.todayCollectedCash = 0.0,
    super.activeDeviceId,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    // ✅ MIGRATION: Support old single-order field → new list field
    List<String> currentOrderIds = [];
    if (json['currentOrderIds'] != null) {
      currentOrderIds = List<String>.from(json['currentOrderIds'] as List);
    } else if (json['currentOrderId'] != null &&
        (json['currentOrderId'] as String).isNotEmpty) {
      // Migrate old documents seamlessly
      currentOrderIds = [json['currentOrderId'] as String];
    }

    return RiderModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      profileImage: json['profileImage'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      vehicleType: json['vehicleType'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      fcmToken: json['fcmToken'] as String?,
      fcmTokenUpdatedAt: _parseTimestampNullable(json['fcmTokenUpdatedAt']),
      totalDeliveries: json['totalDeliveries'] as int? ?? 0,
      approvedAt:
          json['approvedAt'] != null
              ? (json['approvedAt'] as Timestamp).toDate()
              : null,
      approvedBy: json['approvedBy'] as String?,
      status: RiderStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'offline'),
        orElse: () => RiderStatus.offline,
      ),
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      currentOrderIds: currentOrderIds,
      totalCollectedCash:
          (json['totalCollectedCash'] as num?)?.toDouble() ?? 0.0,
      totalDistance: (json['totalDistance'] as num?)?.toDouble() ?? 0.0,
      todayDeliveries: json['todayDeliveries'] as int? ?? 0,
      todayCollectedCash:
          (json['todayCollectedCash'] as num?)?.toDouble() ?? 0.0,
      activeDeviceId: json['activeDeviceId'] as String?,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseTimestampNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'licenseNumber': licenseNumber,
      'isApproved': isApproved,
      'isAvailable': isAvailable,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'fcmToken': fcmToken,
      'fcmTokenUpdatedAt':
          fcmTokenUpdatedAt != null
              ? Timestamp.fromDate(fcmTokenUpdatedAt!)
              : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'status': status.name,
      'totalEarnings': totalEarnings,
      'currentOrderIds': currentOrderIds,
      // Keep old field null for Firestore cleanup
      'currentOrderId': null,
      'totalCollectedCash': totalCollectedCash,
      'totalDistance': totalDistance,
      'todayDeliveries': todayDeliveries,
      'todayCollectedCash': todayCollectedCash,
      'activeDeviceId': activeDeviceId,
    };
  }

  RiderModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseNumber,
    String? fcmToken,
    DateTime? fcmTokenUpdatedAt,
    bool? isApproved,
    bool? isAvailable,
    double? rating,
    int? totalDeliveries,
    DateTime? approvedAt,
    String? approvedBy,
    RiderStatus? status,
    double? totalEarnings,
    List<String>? currentOrderIds,
    double? totalCollectedCash,
    double? totalDistance,
    int? todayDeliveries,
    double? todayCollectedCash,
    String? activeDeviceId,
  }) {
    return RiderModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isApproved: isApproved ?? this.isApproved,
      isAvailable: isAvailable ?? this.isAvailable,
      fcmToken: fcmToken ?? this.fcmToken,
      fcmTokenUpdatedAt: fcmTokenUpdatedAt ?? this.fcmTokenUpdatedAt,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      status: status ?? this.status,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      currentOrderIds: currentOrderIds ?? this.currentOrderIds,
      totalCollectedCash: totalCollectedCash ?? this.totalCollectedCash,
      totalDistance: totalDistance ?? this.totalDistance,
      todayDeliveries: todayDeliveries ?? this.todayDeliveries,
      todayCollectedCash: todayCollectedCash ?? this.todayCollectedCash,
      activeDeviceId: activeDeviceId ?? this.activeDeviceId,
    );
  }
}
