// lib/features/auth/domain/entities/user_entity.dart

import 'package:equatable/equatable.dart';
import '../../../../shared/enums/user_role.dart';

abstract class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.profileImage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        phone,
        role,
        profileImage,
        isActive,
        createdAt,
        updatedAt,
      ];
}