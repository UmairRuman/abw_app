// lib/features/auth/domain/entities/rider_entity.dart
// FULL REPLACEMENT — merges both into ONE entity:

import 'user_entity.dart';

enum RiderStatus { available, busy, offline }

class RiderEntity extends UserEntity {
  // ── Auth / Registration fields ──────────────────
  final String vehicleType;
  final String vehicleNumber;
  final String? licenseNumber;
  final bool isApproved;
  final bool isAvailable;
  final double rating;
  final int totalDeliveries;
  final DateTime? approvedAt;
  final String? approvedBy;

  // ── Rider App operational fields ────────────────
  final RiderStatus status;
  final double totalEarnings;
  final String? currentOrderId;

  const RiderEntity({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    required super.role,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required this.vehicleType,
    required this.vehicleNumber,
    super.fcmToken, // ✅ Pass to parent
    super.fcmTokenUpdatedAt, // ✅ Pass to parent
    super.profileImage,
    this.licenseNumber,
    this.isApproved = false,
    this.isAvailable = false,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.approvedAt,
    this.approvedBy,
    // ── Rider App fields ──
    this.status = RiderStatus.offline,
    this.totalEarnings = 0.0,
    this.currentOrderId,
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
    approvedAt,
    approvedBy,
    status,
    totalEarnings,
    currentOrderId,
  ];
}
