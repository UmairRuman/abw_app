// lib/features/auth/data/models/rider_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/enums/user_role.dart';
import '../../domain/entities/rider_entity.dart';

class RiderModel extends RiderEntity {
  const RiderModel({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
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
  });

  // From JSON
  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: json['userId'] as String,
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
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'role': UserRole.rider.name,
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
    };
  }

  // From Entity
  factory RiderModel.fromEntity(RiderEntity entity) {
    return RiderModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      phone: entity.phone,
      profileImage: entity.profileImage,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      vehicleType: entity.vehicleType,
      vehicleNumber: entity.vehicleNumber,
      licenseNumber: entity.licenseNumber,
      isApproved: entity.isApproved,
      isAvailable: entity.isAvailable,
      rating: entity.rating,
      totalDeliveries: entity.totalDeliveries,
    );
  }

  // To Entity
  RiderEntity toEntity() => this;

  @override
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
    );
  }
}