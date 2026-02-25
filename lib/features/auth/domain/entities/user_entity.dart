// lib/features/auth/domain/entities/user_entity.dart
// UPDATED: Added FCM token fields

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

  // ✅ NEW: FCM Token fields
  final String? fcmToken;
  final DateTime? fcmTokenUpdatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.profileImage,
    this.fcmToken, // ✅ NEW
    this.fcmTokenUpdatedAt, // ✅ NEW
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
    fcmToken, // ✅ NEW
    fcmTokenUpdatedAt, // ✅ NEW
  ];

  // ✅ NEW: Helper method to check if user has valid FCM token
  bool get hasFCMToken => fcmToken != null && fcmToken!.isNotEmpty;
}
