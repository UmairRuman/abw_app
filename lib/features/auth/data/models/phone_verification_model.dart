// lib/features/auth/data/models/phone_verification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneVerificationModel {
  final String userId;
  final String phoneNumber;
  final bool isVerified;
  final String? verificationId;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  PhoneVerificationModel({
    required this.userId,
    required this.phoneNumber,
    this.isVerified = false,
    this.verificationId,
    this.verifiedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
      'verificationId': verificationId,
      'verifiedAt': verifiedAt != null 
          ? Timestamp.fromDate(verifiedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PhoneVerificationModel.fromJson(Map<String, dynamic> json) {
    return PhoneVerificationModel(
      userId: json['userId'] as String,
      phoneNumber: json['phoneNumber'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationId: json['verificationId'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? (json['verifiedAt'] as Timestamp).toDate()
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  PhoneVerificationModel copyWith({
    String? userId,
    String? phoneNumber,
    bool? isVerified,
    String? verificationId,
    DateTime? verifiedAt,
    DateTime? createdAt,
  }) {
    return PhoneVerificationModel(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isVerified: isVerified ?? this.isVerified,
      verificationId: verificationId ?? this.verificationId,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PhoneVerificationModel(userId: $userId, phone: $phoneNumber, verified: $isVerified)';
  }
}