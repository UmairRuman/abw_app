// lib/features/auth/domain/entities/rider_request_entity.dart

import 'package:equatable/equatable.dart';
import '../../../../shared/enums/rider_request_status.dart';

class RiderRequestEntity extends Equatable {
  final String id;
  final String riderId;
  final String riderName;
  final String riderEmail;
  final String riderPhone;
  final String vehicleType;
  final String vehicleNumber;
  final RiderRequestStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const RiderRequestEntity({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.riderEmail,
    required this.riderPhone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
        id,
        riderId,
        riderName,
        riderEmail,
        riderPhone,
        vehicleType,
        vehicleNumber,
        status,
        requestedAt,
        reviewedAt,
        reviewedBy,
        rejectionReason,
      ];

  RiderRequestEntity copyWith({
    String? id,
    String? riderId,
    String? riderName,
    String? riderEmail,
    String? riderPhone,
    String? vehicleType,
    String? vehicleNumber,
    RiderRequestStatus? status,
    DateTime? requestedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return RiderRequestEntity(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderEmail: riderEmail ?? this.riderEmail,
      riderPhone: riderPhone ?? this.riderPhone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}