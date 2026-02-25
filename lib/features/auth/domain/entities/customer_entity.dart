// lib/features/auth/domain/entities/customer_entity.dart
// UPDATED: Added FCM token fields

import 'package:abw_app/shared/enums/user_role.dart';
import 'user_entity.dart';

class CustomerEntity extends UserEntity {
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isPhoneVerified;

  const CustomerEntity({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.profileImage,
    super.fcmToken, // ✅ Pass to parent
    super.fcmTokenUpdatedAt, // ✅ Pass to parent
    this.address,
    this.latitude,
    this.longitude,
    this.isPhoneVerified = false,
  }) : super(role: UserRole.customer);

  @override
  List<Object?> get props => [
    ...super.props,
    address,
    latitude,
    longitude,
    isPhoneVerified,
  ];

  CustomerEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken, // ✅ NEW
    DateTime? fcmTokenUpdatedAt, // ✅ NEW
    String? address,
    double? latitude,
    double? longitude,
    bool? isPhoneVerified,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken, // ✅ NEW
      fcmTokenUpdatedAt: fcmTokenUpdatedAt ?? this.fcmTokenUpdatedAt, // ✅ NEW
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }
}
