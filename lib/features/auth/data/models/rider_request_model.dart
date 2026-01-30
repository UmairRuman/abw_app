// lib/features/auth/data/models/rider_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/enums/rider_request_status.dart';
import '../../domain/entities/rider_request_entity.dart';

class RiderRequestModel extends RiderRequestEntity {
  const RiderRequestModel({
    required super.id,
    required super.riderId,
    required super.riderName,
    required super.riderEmail,
    required super.riderPhone,
    required super.vehicleType,
    required super.vehicleNumber,
    required super.status,
    required super.requestedAt,
    super.reviewedAt,
    super.reviewedBy,
    super.rejectionReason,
  });

  // From JSON
  factory RiderRequestModel.fromJson(Map<String, dynamic> json) {
    return RiderRequestModel(
      id: json['requestId'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      riderEmail: json['riderEmail'] as String,
      riderPhone: json['riderPhone'] as String,
      vehicleType: json['vehicleType'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      status: RiderRequestStatus.fromString(json['status'] as String),
      requestedAt: (json['requestedAt'] as Timestamp).toDate(),
      reviewedAt: json['reviewedAt'] != null
          ? (json['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: json['reviewedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'requestId': id,
      'riderId': riderId,
      'riderName': riderName,
      'riderEmail': riderEmail,
      'riderPhone': riderPhone,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  // From Entity
  factory RiderRequestModel.fromEntity(RiderRequestEntity entity) {
    return RiderRequestModel(
      id: entity.id,
      riderId: entity.riderId,
      riderName: entity.riderName,
      riderEmail: entity.riderEmail,
      riderPhone: entity.riderPhone,
      vehicleType: entity.vehicleType,
      vehicleNumber: entity.vehicleNumber,
      status: entity.status,
      requestedAt: entity.requestedAt,
      reviewedAt: entity.reviewedAt,
      reviewedBy: entity.reviewedBy,
      rejectionReason: entity.rejectionReason,
    );
  }

  // To Entity
  RiderRequestEntity toEntity() => this;

  @override
  RiderRequestModel copyWith({
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
    return RiderRequestModel(
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