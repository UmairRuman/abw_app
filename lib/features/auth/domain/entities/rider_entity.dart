// lib/features/auth/domain/entities/rider_entity.dart

import 'package:abw_app/shared/enums/user_role.dart';

import 'user_entity.dart';

class RiderEntity extends UserEntity {
  final String vehicleType;
  final String vehicleNumber;
  final String? licenseNumber;
  final bool isApproved;
  final bool isAvailable;
  final double rating;
  final int totalDeliveries;

  const RiderEntity({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
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
  }) : super(role: UserRole.rider);

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
      ];

  RiderEntity copyWith({
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
    return RiderEntity(
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