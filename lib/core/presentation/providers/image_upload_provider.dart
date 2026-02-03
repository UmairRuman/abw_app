// lib/core/presentation/providers/image_upload_provider.dart

import 'dart:developer';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/image_upload_collection.dart';

final imageUploadProvider = NotifierProvider<ImageUploadNotifier, ImageUploadState>(
  ImageUploadNotifier.new,
);

class ImageUploadNotifier extends Notifier<ImageUploadState> {
  late final ImageUploadCollection _collection;

  @override
  ImageUploadState build() {
    _collection = ImageUploadCollection();
    return ImageUploadInitial();
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
        final urls = uploadedPublicIds
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
  String getOptimizedUrl(
    String publicId, {
    int? width,
    int? height,
  }) {
    return _collection.getOptimizedUrl(
      publicId,
      width: width,
      height: height,
    );
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