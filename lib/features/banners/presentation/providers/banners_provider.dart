// lib/features/banners/presentation/providers/banners_provider.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final bool isActive;
  final int order;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.isActive,
    required this.order,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'title': title,
    'isActive': isActive,
    'order': order,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  BannerModel copyWith({
    String? imageUrl,
    String? title,
    bool? isActive,
    int? order,
  }) {
    return BannerModel(
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}

// ── State ────────────────────────────────────────────────────────────────────

abstract class BannersState {}

class BannersInitial extends BannersState {}

class BannersLoading extends BannersState {}

class BannersLoaded extends BannersState {
  final List<BannerModel> banners;
  BannersLoaded(this.banners);
}

class BannersError extends BannersState {
  final String message;
  BannersError(this.message);
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class BannersNotifier extends StateNotifier<BannersState> {
  final _firestore = FirebaseFirestore.instance;
  final _collection = 'banners';

  BannersNotifier() : super(BannersInitial());

  Stream<List<BannerModel>> getActiveBannersStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .limit(4)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => BannerModel.fromJson({'id': d.id, ...d.data()}))
                  .toList(),
        );
  }

  Stream<List<BannerModel>> getAllBannersStream() {
    return _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => BannerModel.fromJson({'id': d.id, ...d.data()}))
                  .toList(),
        );
  }

  Future<bool> addBanner({
    required String imageUrl,
    required String title,
    required int order,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final banner = BannerModel(
        id: id,
        imageUrl: imageUrl,
        title: title,
        isActive: true,
        order: order,
        createdAt: DateTime.now(),
      );
      await _firestore.collection(_collection).doc(id).set(banner.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleBanner(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBanner(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateOrder(String id, int order) async {
    try {
      await _firestore.collection(_collection).doc(id).update({'order': order});
      return true;
    } catch (e) {
      return false;
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final bannersProvider = StateNotifierProvider<BannersNotifier, BannersState>(
  (ref) => BannersNotifier(),
);

final activeBannersStreamProvider = StreamProvider<List<BannerModel>>((ref) {
  return BannersNotifier().getActiveBannersStream();
});

final allBannersStreamProvider = StreamProvider<List<BannerModel>>((ref) {
  return BannersNotifier().getAllBannersStream();
});

// Featured products stream — products where tags contains 'Featured', limit 10
final featuredProductsStreamProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .where('tags', arrayContains: 'Featured')
      .where('isAvailable', isEqualTo: true)
      .limit(10)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});
