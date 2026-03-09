// lib/features/settings/data/models/contact_settings_model.dart

class ContactSettingsModel {
  final String bannerUrl;
  final String whatsappNumber;
  final String phoneNumber;
  final DateTime? updatedAt;

  const ContactSettingsModel({
    this.bannerUrl = '',
    this.whatsappNumber = '',
    this.phoneNumber = '',
    this.updatedAt,
  });

  factory ContactSettingsModel.fromJson(Map<String, dynamic> json) {
    return ContactSettingsModel(
      bannerUrl: json['bannerUrl'] as String? ?? '',
      whatsappNumber: json['whatsappNumber'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      updatedAt:
          DateTime.now(), // Set to current time on fetch, since Firestore doesn't return it in the document data
    );
  }

  Map<String, dynamic> toJson() => {
    'bannerUrl': bannerUrl,
    'whatsappNumber': whatsappNumber,
    'phoneNumber': phoneNumber,
    'updatedAt': updatedAt,
  };

  ContactSettingsModel copyWith({
    String? bannerUrl,
    String? whatsappNumber,
    String? phoneNumber,
    DateTime? updatedAt,
  }) {
    return ContactSettingsModel(
      bannerUrl: bannerUrl ?? this.bannerUrl,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static ContactSettingsModel get empty => const ContactSettingsModel();
}
