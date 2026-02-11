// lib/features/riders/domain/entities/rider_entity.dart

import 'package:equatable/equatable.dart';

enum RiderStatus { available, busy, offline }

class RiderEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final RiderStatus status;
  final bool isApproved;
  final double totalEarnings;
  final int totalDeliveries;
  final double rating;
  final String? currentOrderId;
  final DateTime createdAt;

  const RiderEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.isApproved,
    required this.totalEarnings,
    required this.totalDeliveries,
    required this.rating,
    this.currentOrderId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        status,
        isApproved,
        totalEarnings,
        totalDeliveries,
        rating,
        currentOrderId,
        createdAt,
      ];
}