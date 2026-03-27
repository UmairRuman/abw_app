// lib/features/stores/data/models/store_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final String type;

  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;

  final List<String> images;
  final String logoUrl;
  final String bannerUrl;

  final String address;
  final String city;
  final String area;
  final double latitude;
  final double longitude;

  final double rating;
  final int totalReviews;
  final int totalOrders;

  final int deliveryTime;
  final double deliveryFee;
  final double minimumOrder;
  final double commission;

  final bool isActive;
  final bool isApproved;
  final bool isFeatured;
  final bool isOpen; // stored flag — used as manual override / fallback

  final String openingTime;
  final String closingTime;
  final List<String> workingDays;

  final List<String> cuisines;
  final List<String> tags;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;

  StoreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.type,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.images,
    required this.logoUrl,
    required this.bannerUrl,
    required this.address,
    required this.city,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minimumOrder,
    required this.openingTime,
    required this.closingTime,
    required this.workingDays,
    required this.createdAt,
    required this.updatedAt,
    this.commission = 0.0,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.isActive = true,
    this.isApproved = false,
    this.isFeatured = false,
    this.isOpen = true,
    this.cuisines = const [],
    this.tags = const [],
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
  });

  // ── ✅ FIX: Computed open/closed status ───────────────────────────────────
  //
  // Previously the UI read `store.isOpen` which is a static boolean saved in
  // Firestore — it never changed based on actual time, so stores always
  // appeared open (defaulted to true). This getter computes the real status
  // from openingTime, closingTime and workingDays at call time.
  //
  // Falls back to the stored `isOpen` boolean only when time strings are
  // missing or unparseable (e.g. legacy stores with no hours configured).

  bool get isCurrentlyOpen {
    // If store is inactive, it's always closed regardless of hours
    if (!isActive) return false;

    // If no hours configured, fall back to stored boolean
    if (openingTime.isEmpty || closingTime.isEmpty) return isOpen;

    final now = DateTime.now();

    // Check working days
    if (workingDays.isNotEmpty) {
      const dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final todayName = dayNames[now.weekday - 1]; // weekday: 1=Mon … 7=Sun
      if (!workingDays.contains(todayName)) return false;
    }

    // Parse time strings — supports "8:00 AM", "8:00 PM", "08:00", "20:00"
    final openMinutes = _parseTimeToMinutes(openingTime);
    final closeMinutes = _parseTimeToMinutes(closingTime);

    // If parsing fails, fall back to stored boolean
    if (openMinutes == null || closeMinutes == null) return isOpen;

    final nowMinutes = now.hour * 60 + now.minute;

    // Handle overnight hours (e.g. 10 PM to 2 AM)
    if (closeMinutes < openMinutes) {
      return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
    }

    return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
  }

  /// Parses "8:00 AM", "8:00 PM", "08:00", "20:00" → total minutes since midnight.
  /// Returns null if the string cannot be parsed.
  int? _parseTimeToMinutes(String timeStr) {
    try {
      final trimmed = timeStr.trim().toUpperCase();
      final isPM = trimmed.endsWith('PM');
      final isAM = trimmed.endsWith('AM');

      // Strip AM/PM suffix
      final cleaned = trimmed.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = cleaned.split(':');
      if (parts.length < 2) return null;

      int hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());

      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0; // midnight edge case

      return hour * 60 + minute;
    } catch (_) {
      return null;
    }
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'type': type,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPhone': ownerPhone,
      'images': images,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'address': address,
      'city': city,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalOrders': totalOrders,
      'deliveryTime': deliveryTime,
      'deliveryFee': deliveryFee,
      'minimumOrder': minimumOrder,
      'commission': commission,
      'isActive': isActive,
      'isApproved': isApproved,
      'isFeatured': isFeatured,
      'isOpen': isOpen,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'workingDays': workingDays,
      'cuisines': cuisines,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      type: json['type'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      ownerEmail: json['ownerEmail'] as String,
      ownerPhone: json['ownerPhone'] as String,
      images: List<String>.from(json['images'] as List),
      logoUrl: json['logoUrl'] as String,
      bannerUrl: json['bannerUrl'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      area: json['area'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      deliveryTime: json['deliveryTime'] as int,
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      minimumOrder: (json['minimumOrder'] as num).toDouble(),
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      isApproved: json['isApproved'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isOpen: json['isOpen'] as bool? ?? true,
      openingTime: json['openingTime'] as String? ?? '',
      closingTime: json['closingTime'] as String? ?? '',
      workingDays:
          json['workingDays'] != null
              ? List<String>.from(json['workingDays'] as List)
              : [],
      cuisines:
          json['cuisines'] != null
              ? List<String>.from(json['cuisines'] as List)
              : [],
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      approvedAt:
          json['approvedAt'] != null
              ? (json['approvedAt'] as Timestamp).toDate()
              : null,
      approvedBy: json['approvedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  StoreModel copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    String? type,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
    List<String>? images,
    String? logoUrl,
    String? bannerUrl,
    String? address,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    int? deliveryTime,
    double? deliveryFee,
    double? minimumOrder,
    double? commission,
    bool? isActive,
    bool? isApproved,
    bool? isFeatured,
    bool? isOpen,
    String? openingTime,
    String? closingTime,
    List<String>? workingDays,
    List<String>? cuisines,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectionReason,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      images: images ?? this.images,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      commission: commission ?? this.commission,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      isFeatured: isFeatured ?? this.isFeatured,
      isOpen: isOpen ?? this.isOpen,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      workingDays: workingDays ?? this.workingDays,
      cuisines: cuisines ?? this.cuisines,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  factory StoreModel.empty() {
    return StoreModel(
      id: '',
      name: '',
      description: '',
      categoryId: '',
      categoryName: '',
      type: '',
      ownerId: '',
      ownerName: '',
      ownerEmail: '',
      ownerPhone: '',
      images: [],
      logoUrl: '',
      bannerUrl: '',
      address: '',
      city: '',
      area: '',
      latitude: 0.0,
      longitude: 0.0,
      deliveryTime: 0,
      deliveryFee: 0.0,
      minimumOrder: 0.0,
      commission: 0.0,
      openingTime: '',
      closingTime: '',
      workingDays: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'StoreModel(id: $id, name: $name, isCurrentlyOpen: $isCurrentlyOpen)';
}
