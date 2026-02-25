// lib/features/auth/data/models/rider_model.dart
// FULL REPLACEMENT:

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
    super.fcmToken, // ✅ NEW
    super.fcmTokenUpdatedAt, // ✅ NEW
    super.role = UserRole.rider,
    super.profileImage,
    super.licenseNumber,
    super.isApproved = false,
    super.isAvailable = false,
    super.rating = 0.0,
    super.totalDeliveries = 0,
    super.approvedAt,
    super.approvedBy,
    // ── Rider App fields ──
    super.status = RiderStatus.offline,
    super.totalEarnings = 0.0,
    super.currentOrderId,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      profileImage: json['profileImage'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(json['createdAt']), // ✅ LINE 1
      updatedAt: _parseTimestamp(json['updatedAt']),
      vehicleType: json['vehicleType'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      fcmToken: json['fcmToken'] as String?, // ✅ NEW
      fcmTokenUpdatedAt: _parseTimestamp(json['fcmTokenUpdatedAt']), // ✅ NEW
      totalDeliveries: json['totalDeliveries'] as int? ?? 0,
      approvedAt:
          json['approvedAt'] != null
              ? (json['approvedAt'] as Timestamp).toDate()
              : null,
      approvedBy: json['approvedBy'] as String?,
      // ── Rider App fields ──
      status: RiderStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'offline'),
        orElse: () => RiderStatus.offline,
      ),
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      currentOrderId: json['currentOrderId'] as String?,
    );
  }
  // ✅ ADD THIS STATIC HELPER AT BOTTOM OF CLASS (before closing })
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
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
      'fcmToken': fcmToken, // ✅ NEW
      'fcmTokenUpdatedAt':
          fcmTokenUpdatedAt !=
                  null // ✅ NEW
              ? Timestamp.fromDate(fcmTokenUpdatedAt!)
              : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      // ── Rider App fields ──
      'status': status.name,
      'totalEarnings': totalEarnings,
      'currentOrderId': currentOrderId,
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
    String? fcmToken, // ✅ NEW
    DateTime? fcmTokenUpdatedAt, // ✅ NEW
    bool? isApproved,
    bool? isAvailable,
    double? rating,
    int? totalDeliveries,
    DateTime? approvedAt,
    String? approvedBy,
    // ── Rider App fields ──
    RiderStatus? status,
    double? totalEarnings,
    String? currentOrderId,
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
      fcmToken: fcmToken ?? this.fcmToken, // ✅ NEW
      fcmTokenUpdatedAt: fcmTokenUpdatedAt ?? this.fcmTokenUpdatedAt, // ✅ NEW
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      status: status ?? this.status,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      currentOrderId: currentOrderId ?? this.currentOrderId,
    );
  }
}
