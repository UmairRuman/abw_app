// lib/features/auth/data/models/rider_model.dart

import 'package:abw_app/shared/enums/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/rider_entity.dart';

class RiderModel extends RiderEntity {
  const RiderModel({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    super.role = UserRole.rider,
    super.profileImage,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.vehicleType,
    required super.vehicleNumber,
    super.licenseNumber,
    super.isApproved = false,
    super.isAvailable = false,
    super.rating = 0.0,
    super.totalDeliveries = 0,
    super.approvedAt,    // ✅ ADD THIS
    super.approvedBy,    // ✅ ADD THIS
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      profileImage: json['profileImage'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      vehicleType: json['vehicleType'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      licenseNumber: json['licenseNumber'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalDeliveries: json['totalDeliveries'] as int? ?? 0,
      approvedAt: json['approvedAt'] != null        // ✅ ADD THIS
          ? (json['approvedAt'] as Timestamp).toDate()
          : null,
      approvedBy: json['approvedBy'] as String?,    // ✅ ADD THIS
    );
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
      'approvedAt': approvedAt != null              // ✅ ADD THIS
          ? Timestamp.fromDate(approvedAt!)
          : null,
      'approvedBy': approvedBy,                     // ✅ ADD THIS
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
    bool? isApproved,
    bool? isAvailable,
    double? rating,
    int? totalDeliveries,
    DateTime? approvedAt,    // ✅ ADD THIS
    String? approvedBy,      // ✅ ADD THIS
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
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      approvedAt: approvedAt ?? this.approvedAt,        // ✅ ADD THIS
      approvedBy: approvedBy ?? this.approvedBy,        // ✅ ADD THIS
    );
  }
}