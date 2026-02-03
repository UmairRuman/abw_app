// lib/features/auth/domain/entities/rider_entity.dart

import 'user_entity.dart';

class RiderEntity extends UserEntity {
  final String vehicleType;
  final String vehicleNumber;
  final String? licenseNumber;
  final bool isApproved;
  final bool isAvailable;
  final double rating;
  final int totalDeliveries;
  final DateTime? approvedAt;  // ✅ ADD THIS
  final String? approvedBy;    // ✅ ADD THIS (optional - who approved)

  const RiderEntity({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    required super.role,
    super.profileImage,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required this.vehicleType,
    required this.vehicleNumber,
    this.licenseNumber,
    this.isApproved = false,
    this.isAvailable = false,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.approvedAt,     // ✅ ADD THIS
    this.approvedBy,     // ✅ ADD THIS
  });

  @override
  List<Object?> get props => [
        ...super.props,
        vehicleType,
        vehicleNumber,
        licenseNumber,
        isApproved,
        isAvailable,
        rating,
        totalDeliveries,
        approvedAt,    // ✅ ADD THIS
        approvedBy,    // ✅ ADD THIS
      ];
}