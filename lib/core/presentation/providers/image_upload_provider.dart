// lib/core/presentation/providers/image_upload_provider.dart

import 'dart:developer';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/image_upload_collection.dart';

final imageUploadProvider =
    NotifierProvider<ImageUploadNotifier, ImageUploadState>(
      ImageUploadNotifier.new,
    );

class ImageUploadNotifier extends Notifier<ImageUploadState> {
  late final ImageUploadCollection _collection;

  @override
  ImageUploadState build() {
    _collection = ImageUploadCollection();
    return ImageUploadInitial();
  }

  // Upload payment proof screenshots
  // Upload payment proof screenshots
  Future<List<String>> uploadPaymentProof(List<File> images) async {
    try {
      final uploadedUrls = <String>[];

      for (final image in images) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final publicId = 'proof_$timestamp';

        final uploadedPublicId = await _collection.uploadImage(
          imageFile: image,
          folder: 'abw_app/payment_proofs',
          publicId: publicId,
          onProgress: (progress) {
            state = ImageUploading(progress: progress);
          },
        );

        if (uploadedPublicId != null) {
          // ✅ ROOT CAUSE FIX:
          // getOptimizedUrl() with no width/height generates:
          //   /image/upload/c_fill,q_auto,f_auto/...
          // c_fill WITHOUT w_ and h_ is an invalid Cloudinary transformation
          // and returns a 400 error — that's why the image never loads.
          //
          // Payment proofs don't need cropping/resizing — just deliver the
          // original JPEG at auto quality. No c_fill, no f_auto.
          final url =
              '${_collection.baseImageUrl}/q_auto,f_jpg/$uploadedPublicId';
          uploadedUrls.add(url);
        }
      }

      return uploadedUrls;
    } catch (e) {
      log('Error uploading payment proof: $e');
      return [];
    }
  }

  String _forceJpgFormat(String url) {
    if (!url.contains('cloudinary.com')) return url;
    if (url.contains('f_auto')) return url.replaceAll('f_auto', 'f_jpg');
    if (url.contains('f_png')) return url.replaceAll('f_png', 'f_jpg');
    if (url.contains('f_webp')) return url.replaceAll('f_webp', 'f_jpg');
    // No format token — inject before the asset path
    return url.replaceFirstMapped(
      RegExp(r'(/image/upload/)'),
      (m) => '${m[1]}f_jpg/',
    );
  }

  /// Upload single image
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    String? publicId,
    String? transformation,
  }) async {
    // Validate image
    if (!_collection.validateImage(imageFile)) {
      state = ImageUploadError(error: 'Invalid image file');
      return null;
    }

    state = ImageUploading(progress: 0.0);

    try {
      final uploadedPublicId = await _collection.uploadImage(
        imageFile: imageFile,
        folder: folder,
        publicId: publicId,
        transformation: transformation,
        onProgress: (progress) {
          state = ImageUploading(progress: progress);
        },
      );

      if (uploadedPublicId != null) {
        final url = _collection.getOptimizedUrl(uploadedPublicId);
        state = ImageUploaded(url: url, publicId: uploadedPublicId);
        return uploadedPublicId;
      } else {
        state = ImageUploadError(error: 'Failed to upload image');
        return null;
      }
    } catch (e) {
      state = ImageUploadError(error: e.toString());
      log('Error in uploadImage: ${e.toString()}');
      return null;
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
    String? transformation,
  }) async {
    // Validate all images
    for (var file in imageFiles) {
      if (!_collection.validateImage(file)) {
        state = ImageUploadError(error: 'One or more invalid image files');
        return [];
      }
    }

    state = ImageUploading(progress: 0.0);

    try {
      final uploadedPublicIds = await _collection.uploadMultipleImages(
        imageFiles: imageFiles,
        folder: folder,
        transformation: transformation,
        onProgress: (progress) {
          state = ImageUploading(progress: progress);
        },
      );

      if (uploadedPublicIds.isNotEmpty) {
        final urls =
            uploadedPublicIds
                .map((id) => _collection.getOptimizedUrl(id))
                .toList();

        state = ImagesUploaded(urls: urls, publicIds: uploadedPublicIds);
        return uploadedPublicIds;
      } else {
        state = ImageUploadError(error: 'Failed to upload images');
        return [];
      }
    } catch (e) {
      state = ImageUploadError(error: e.toString());
      log('Error in uploadMultipleImages: ${e.toString()}');
      return [];
    }
  }

  /// Upload category icon
  Future<String?> uploadCategoryIcon(File imageFile, String categoryId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'categories/icons',
      publicId: 'category_$categoryId',
    );
  }

  /// Upload store logo
  Future<String?> uploadStoreLogo(File imageFile, String storeId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'stores/logos',
      publicId: 'store_logo_$storeId',
    );
  }

  /// Upload store banner
  Future<String?> uploadStoreBanner(File imageFile, String storeId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'stores/banners',
      publicId: 'store_banner_$storeId',
    );
  }

  /// Upload store images - ✅ THIS WAS MISSING
  Future<List<String>> uploadStoreImages(
    List<File> imageFiles,
    String storeId,
  ) async {
    return await uploadMultipleImages(
      imageFiles: imageFiles,
      folder: 'stores/images/$storeId',
    );
  }

  /// Upload product images
  Future<List<String>> uploadProductImages(
    List<File> imageFiles,
    String productId,
  ) async {
    return await uploadMultipleImages(
      imageFiles: imageFiles,
      folder: 'products/images/$productId',
    );
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'profiles',
      publicId: 'profile_$userId',
    );
  }

  /// Delete image
  Future<bool> deleteImage(String publicId) async {
    try {
      return await _collection.deleteImage(publicId);
    } catch (e) {
      log('Error deleting image: ${e.toString()}');
      return false;
    }
  }

  /// Get optimized URL
  String getOptimizedUrl(String publicId, {int? width, int? height}) {
    return _collection.getOptimizedUrl(publicId, width: width, height: height);
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String publicId) {
    return _collection.getThumbnailUrl(publicId);
  }

  /// Reset state
  void reset() {
    state = ImageUploadInitial();
  }
}

// States
abstract class ImageUploadState {}

class ImageUploadInitial extends ImageUploadState {}

class ImageUploading extends ImageUploadState {
  final double progress;

  ImageUploading({required this.progress});
}

class ImageUploaded extends ImageUploadState {
  final String url;
  final String publicId;

  ImageUploaded({required this.url, required this.publicId});
}

class ImagesUploaded extends ImageUploadState {
  final List<String> urls;
  final List<String> publicIds;

  ImagesUploaded({required this.urls, required this.publicIds});
}

class ImageUploadError extends ImageUploadState {
  final String error;

  ImageUploadError({required this.error});
}
