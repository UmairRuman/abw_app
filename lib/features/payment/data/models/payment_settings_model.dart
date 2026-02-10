// lib/features/payment/data/models/payment_settings_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSettingsModel {
  final String id;
  final String jazzcashNumber;
  final String easypaisaNumber;
  final String bankAccountTitle;
  final String bankAccountNumber;
  final String bankName;
  final bool isCodEnabled;
  final bool isJazzcashEnabled;
  final bool isEasypaisaEnabled;
  final bool isBankTransferEnabled;
  final DateTime updatedAt;
  final String updatedBy;

  const PaymentSettingsModel({
    required this.id,
    required this.jazzcashNumber,
    required this.easypaisaNumber,
    required this.bankAccountTitle,
    required this.bankAccountNumber,
    required this.bankName,
    required this.isCodEnabled,
    required this.isJazzcashEnabled,
    required this.isEasypaisaEnabled,
    required this.isBankTransferEnabled,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory PaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    return PaymentSettingsModel(
      id: json['id'] as String? ?? 'payment_settings',
      jazzcashNumber: json['jazzcashNumber'] as String? ?? '',
      easypaisaNumber: json['easypaisaNumber'] as String? ?? '',
      bankAccountTitle: json['bankAccountTitle'] as String? ?? '',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      isCodEnabled: json['isCodEnabled'] as bool? ?? true,
      isJazzcashEnabled: json['isJazzcashEnabled'] as bool? ?? true,
      isEasypaisaEnabled: json['isEasypaisaEnabled'] as bool? ?? true,
      isBankTransferEnabled: json['isBankTransferEnabled'] as bool? ?? true,
      updatedAt:
          json['updatedAt'] != null
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedBy: json['updatedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jazzcashNumber': jazzcashNumber,
      'easypaisaNumber': easypaisaNumber,
      'bankAccountTitle': bankAccountTitle,
      'bankAccountNumber': bankAccountNumber,
      'bankName': bankName,
      'isCodEnabled': isCodEnabled,
      'isJazzcashEnabled': isJazzcashEnabled,
      'isEasypaisaEnabled': isEasypaisaEnabled,
      'isBankTransferEnabled': isBankTransferEnabled,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  // Default settings
  factory PaymentSettingsModel.defaultSettings() {
    return PaymentSettingsModel(
      id: 'payment_settings',
      jazzcashNumber: '03072740036',
      easypaisaNumber: '03072740036',
      bankAccountTitle: 'ABW Services',
      bankAccountNumber: '03072740036',
      bankName: 'HBL / Meezan Bank',
      isCodEnabled: true,
      isJazzcashEnabled: true,
      isEasypaisaEnabled: true,
      isBankTransferEnabled: true,
      updatedAt: DateTime.now(),
      updatedBy: 'admin',
    );
  }

  PaymentSettingsModel copyWith({
    String? jazzcashNumber,
    String? easypaisaNumber,
    String? bankAccountTitle,
    String? bankAccountNumber,
    String? bankName,
    bool? isCodEnabled,
    bool? isJazzcashEnabled,
    bool? isEasypaisaEnabled,
    bool? isBankTransferEnabled,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return PaymentSettingsModel(
      id: id,
      jazzcashNumber: jazzcashNumber ?? this.jazzcashNumber,
      easypaisaNumber: easypaisaNumber ?? this.easypaisaNumber,
      bankAccountTitle: bankAccountTitle ?? this.bankAccountTitle,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      isCodEnabled: isCodEnabled ?? this.isCodEnabled,
      isJazzcashEnabled: isJazzcashEnabled ?? this.isJazzcashEnabled,
      isEasypaisaEnabled: isEasypaisaEnabled ?? this.isEasypaisaEnabled,
      isBankTransferEnabled:
          isBankTransferEnabled ?? this.isBankTransferEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
