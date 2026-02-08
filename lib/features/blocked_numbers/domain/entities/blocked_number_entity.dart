// lib/features/blocked_numbers/domain/entities/blocked_number_entity.dart

import 'package:equatable/equatable.dart';

class BlockedNumberEntity extends Equatable {
  final String id; // Document ID
  final String phoneNumber; // The blocked number
  final String? userId; // Optional: Link to user who was blocked
  final String blockedBy; // Admin ID who blocked
  final String blockedByName; // Admin name
  final String reason; // Reason for blocking
  final DateTime blockedAt;
  final bool isActive; // Can temporarily unblock without deleting

  const BlockedNumberEntity({
    required this.id,
    required this.phoneNumber,
    this.userId,
    required this.blockedBy,
    required this.blockedByName,
    required this.reason,
    required this.blockedAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    id,
    phoneNumber,
    userId,
    blockedBy,
    blockedByName,
    reason,
    blockedAt,
    isActive,
  ];
}
