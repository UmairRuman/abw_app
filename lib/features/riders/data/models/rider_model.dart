// lib/features/riders/data/models/rider_model.dart

import '../../domain/entities/rider_entity.dart';

class RiderModel extends RiderEntity {
  const RiderModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.status,
    required super.isApproved,
    required super.totalEarnings,
    required super.totalDeliveries,
    required super.rating,
    super.currentOrderId,
    required super.createdAt,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      status: RiderStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'offline'),
        orElse: () => RiderStatus.offline,
      ),
      isApproved: json['isApproved'] as bool? ?? false,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      totalDeliveries: json['totalDeliveries'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      currentOrderId: json['currentOrderId'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status.name,
      'isApproved': isApproved,
      'totalEarnings': totalEarnings,
      'totalDeliveries': totalDeliveries,
      'rating': rating,
      'currentOrderId': currentOrderId,
      'createdAt': createdAt,
    };
  }

  RiderModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    RiderStatus? status,
    bool? isApproved,
    double? totalEarnings,
    int? totalDeliveries,
    double? rating,
    String? currentOrderId,
    DateTime? createdAt,
  }) {
    return RiderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      isApproved: isApproved ?? this.isApproved,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      rating: rating ?? this.rating,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}