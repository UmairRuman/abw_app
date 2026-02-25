// lib/features/auth/domain/entities/admin_entity.dart

import '../../../../shared/enums/user_role.dart';
import 'user_entity.dart';

class AdminEntity extends UserEntity {
  final String accessKey;
  final List<String> permissions;

  const AdminEntity({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required this.accessKey,
    super.fcmToken, // ✅ Pass to parent
    super.fcmTokenUpdatedAt, // ✅ Pass to parent
    super.profileImage,
    this.permissions = const [],
  }) : super(role: UserRole.admin);

  @override
  List<Object?> get props => [...super.props, accessKey, permissions];

  AdminEntity copyWith({
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
    String? accessKey,
    List<String>? permissions,
  }) {
    return AdminEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      fcmToken: fcmToken ?? this.fcmToken, // ✅ NEW
      fcmTokenUpdatedAt: fcmTokenUpdatedAt ?? this.fcmTokenUpdatedAt, // ✅ NEW
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accessKey: accessKey ?? this.accessKey,
      permissions: permissions ?? this.permissions,
    );
  }
}
