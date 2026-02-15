// lib/features/auth/domain/entities/customer_entity.dart

import 'package:abw_app/shared/enums/user_role.dart';
import 'user_entity.dart';

class CustomerEntity extends UserEntity {
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isPhoneVerified; // ✅ NEW FIELD

  const CustomerEntity({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.profileImage,
    this.address,
    this.latitude,
    this.longitude,
    this.isPhoneVerified = false, // ✅ DEFAULT FALSE
  }) : super(role: UserRole.customer);

  @override
  List<Object?> get props => [
    ...super.props,
    address,
    latitude,
    longitude,
    isPhoneVerified, // ✅ ADD TO PROPS
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
    String? address,
    double? latitude,
    double? longitude,
    bool? isPhoneVerified, // ✅ ADD TO COPYWITH
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
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified, // ✅
    );
  }
}
