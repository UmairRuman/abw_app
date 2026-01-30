// lib/features/auth/data/models/customer_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/enums/user_role.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    super.profileImage,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.address,
    super.latitude,
    super.longitude,
  });

  // From JSON
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['userId'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      profileImage: json['profileImage'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'role': UserRole.customer.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // From Entity
  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      phone: entity.phone,
      profileImage: entity.profileImage,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }

  // To Entity
  CustomerEntity toEntity() => this;

  @override
  CustomerModel copyWith({
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
  }) {
    return CustomerModel(
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
    );
  }
}