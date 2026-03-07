// lib/features/auth/domain/entities/rider_entity.dart
// UPDATED: Multi-order, analytics (no salary), device lock

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
  final double totalEarnings; // Internal/admin only — NOT shown to rider
  final List<String>
  currentOrderIds; // ✅ MULTI-ORDER: replaces single currentOrderId

  // ✅ NEW: Analytics visible to rider (no salary/earnings)
  final double totalCollectedCash; // Total COD cash collected from customers
  final double totalDistance; // Total km/m covered across all deliveries
  final int todayDeliveries; // Reset by admin: "clear today's records"
  final double todayCollectedCash; // Reset by admin: "clear collected rupees"

  // ✅ NEW: Device lock
  final String? activeDeviceId;

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
    super.fcmToken,
    super.fcmTokenUpdatedAt,
    super.profileImage,
    this.licenseNumber,
    this.isApproved = false,
    this.isAvailable = false,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.approvedAt,
    this.approvedBy,
    this.status = RiderStatus.offline,
    this.totalEarnings = 0.0,
    this.currentOrderIds = const [],
    this.totalCollectedCash = 0.0,
    this.totalDistance = 0.0,
    this.todayDeliveries = 0,
    this.todayCollectedCash = 0.0,
    this.activeDeviceId,
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
    currentOrderIds,
    totalCollectedCash,
    totalDistance,
    todayDeliveries,
    todayCollectedCash,
    activeDeviceId,
  ];
}
