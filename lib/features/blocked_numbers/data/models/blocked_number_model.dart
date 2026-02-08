// lib/features/blocked_numbers/data/models/blocked_number_model.dart

import 'package:abw_app/features/blocked_numbers/domain/entities/blocked_number_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedNumberModel extends BlockedNumberEntity {
  const BlockedNumberModel({
    required super.id,
    required super.phoneNumber,
    super.userId,
    required super.blockedBy,
    required super.blockedByName,
    required super.reason,
    required super.blockedAt,
    super.isActive,
  });

  // From JSON
  factory BlockedNumberModel.fromJson(Map<String, dynamic> json) {
    return BlockedNumberModel(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      userId: json['userId'] as String?,
      blockedBy: json['blockedBy'] as String,
      blockedByName: json['blockedByName'] as String,
      reason: json['reason'] as String,
      blockedAt: (json['blockedAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'userId': userId,
      'blockedBy': blockedBy,
      'blockedByName': blockedByName,
      'reason': reason,
      'blockedAt': Timestamp.fromDate(blockedAt),
      'isActive': isActive,
    };
  }

  // CopyWith
  BlockedNumberModel copyWith({
    String? id,
    String? phoneNumber,
    String? userId,
    String? blockedBy,
    String? blockedByName,
    String? reason,
    DateTime? blockedAt,
    bool? isActive,
  }) {
    return BlockedNumberModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
      blockedBy: blockedBy ?? this.blockedBy,
      blockedByName: blockedByName ?? this.blockedByName,
      reason: reason ?? this.reason,
      blockedAt: blockedAt ?? this.blockedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
