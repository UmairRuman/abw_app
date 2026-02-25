// lib/features/auth/data/models/admin_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/enums/user_role.dart';
import '../../domain/entities/admin_entity.dart';

class AdminModel extends AdminEntity {
  const AdminModel({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.accessKey,
    super.fcmToken, // ✅ NEW
    super.fcmTokenUpdatedAt, // ✅ NEW
    super.profileImage,
    super.permissions = const [],
  });

  // From JSON
  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['userId'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      profileImage: json['profileImage'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      fcmToken: json['fcmToken'] as String?, // ✅ NEW
      fcmTokenUpdatedAt: _parseTimestamp(json['fcmTokenUpdatedAt']), // ✅ NEW
      accessKey: json['accessKey'] as String,
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'role': UserRole.admin.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'fcmToken': fcmToken, // ✅ NEW
      'fcmTokenUpdatedAt':
          fcmTokenUpdatedAt !=
                  null // ✅ NEW
              ? Timestamp.fromDate(fcmTokenUpdatedAt!)
              : null,
      'accessKey': accessKey,
      'permissions': permissions,
    };
  }

  // From Entity
  factory AdminModel.fromEntity(AdminEntity entity) {
    return AdminModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      phone: entity.phone,
      profileImage: entity.profileImage,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      accessKey: entity.accessKey,
      fcmToken: entity.fcmToken, // ✅ NEW
      fcmTokenUpdatedAt: entity.fcmTokenUpdatedAt, // ✅ NEW
      permissions: entity.permissions,
    );
  }

  // To Entity
  AdminEntity toEntity() => this;

  @override
  AdminModel copyWith({
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
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accessKey: accessKey ?? this.accessKey,
      fcmToken: fcmToken ?? this.fcmToken, // ✅ NEW
      fcmTokenUpdatedAt: fcmTokenUpdatedAt ?? this.fcmTokenUpdatedAt, // ✅ NEW
      permissions: permissions ?? this.permissions,
    );
  }
}
