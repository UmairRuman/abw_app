// lib/core/data/collections/image_upload_collection.dart

import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../constants/cloudinary_constants.dart';

class ImageUploadCollection {
  // Singleton pattern
  static final ImageUploadCollection instance = ImageUploadCollection._internal();
  ImageUploadCollection._internal();
  
  factory ImageUploadCollection() {
    return instance;
  }

  /// Upload image to Cloudinary
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    String? publicId,
    String? transformation,
    Function(double)? onProgress,
  }) async {
    try {
      // Compress image before upload
      final compressedFile = await _compressImage(imageFile);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConstants.uploadUrl),
      );

      // Add fields
      request.fields['upload_preset'] = CloudinaryConstants.uploadPreset;
      request.fields['folder'] = folder;
      
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }

      if (transformation != null) {
        request.fields['transformation'] = transformation;
      }

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        compressedFile.path,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final publicId = jsonResponse['public_id'] as String;
        final secureUrl = jsonResponse['secure_url'] as String;

        log('Image uploaded successfully: $secureUrl');
        
        // Clean up compressed file
        await compressedFile.delete();
        
        return publicId; // Return public_id for future transformations
      } else {
        log('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error uploading image: ${e.toString()}');
      return null;
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
    String? transformation,
    Function(double)? onProgress,
  }) async {
    List<String> uploadedPublicIds = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final publicId = await uploadImage(
        imageFile: imageFiles[i],
        folder: folder,
        transformation: transformation,
        onProgress: (progress) {
          // Calculate overall progress
          final overallProgress = ((i + progress) / imageFiles.length) * 100;
          onProgress?.call(overallProgress);
        },
      );

      if (publicId != null) {
        uploadedPublicIds.add(publicId);
      }
    }

    log('Uploaded ${uploadedPublicIds.length}/${imageFiles.length} images');
    return uploadedPublicIds;
  }

  /// Upload category icon
  Future<String?> uploadCategoryIcon(File imageFile, String categoryId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: CloudinaryConstants.categoryIconsFolder,
      publicId: 'category_$categoryId',
      transformation: CloudinaryConstants.categoryIconTransform,
    );
  }

  /// Upload store logo
  Future<String?> uploadStoreLogo(File imageFile, String storeId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: CloudinaryConstants.storeLogosFolder,
      publicId: 'store_logo_$storeId',
      transformation: CloudinaryConstants.storeLogoTransform,
    );
  }

  /// Upload store banner
  Future<String?> uploadStoreBanner(File imageFile, String storeId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: CloudinaryConstants.storeBannersFolder,
      publicId: 'store_banner_$storeId',
      transformation: CloudinaryConstants.storeBannerTransform,
    );
  }

  /// Upload store images
  Future<List<String>> uploadStoreImages(
    List<File> imageFiles,
    String storeId,
  ) async {
    return await uploadMultipleImages(
      imageFiles: imageFiles,
      folder: '${CloudinaryConstants.storeImagesFolder}/$storeId',
      transformation: CloudinaryConstants.productImageTransform,
    );
  }

  /// Upload product images
  Future<List<String>> uploadProductImages(
    List<File> imageFiles,
    String productId,
  ) async {
    return await uploadMultipleImages(
      imageFiles: imageFiles,
      folder: '${CloudinaryConstants.productImagesFolder}/$productId',
      transformation: CloudinaryConstants.productImageTransform,
    );
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: CloudinaryConstants.profileImagesFolder,
      publicId: 'profile_$userId',
      transformation: CloudinaryConstants.profileImageTransform,
    );
  }

  /// Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      // Generate signature for deletion (requires API secret)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Note: For production, you should implement signature generation
      // using cloudinary SDK or server-side API
      
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConstants.cloudName}/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': CloudinaryConstants.apiKey,
          'timestamp': timestamp,
          // 'signature': signature, // Generate this on server side
        },
      );

      if (response.statusCode == 200) {
        log('Image deleted successfully: $publicId');
        return true;
      }

      log('Failed to delete image: ${response.statusCode}');
      return false;
    } catch (e) {
      log('Error deleting image: ${e.toString()}');
      return false;
    }
  }

  /// Compress image before upload
  Future<File> _compressImage(File file, {int quality = 80}) async {
    try {
      // Read image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return file;

      // Resize if too large (max 1920px)
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1920) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1920 : null,
        );
      }

      // Compress
      final compressedBytes = img.encodeJpg(resized, quality: quality);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      final originalSize = bytes.length / 1024; // KB
      final compressedSize = compressedBytes.length / 1024; // KB
      log('Image compressed: ${originalSize.toStringAsFixed(2)} KB → ${compressedSize.toStringAsFixed(2)} KB');

      return tempFile;
    } catch (e) {
      log('Error compressing image: ${e.toString()}');
      return file;
    }
  }

  /// Validate image file
  bool validateImage(File file) {
    // Check file size (max 5MB)
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    if (sizeInMB > 5) {
      log('Image too large: ${sizeInMB.toStringAsFixed(2)} MB');
      return false;
    }

    // Check file extension
    final extension = file.path.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    
    if (!allowedExtensions.contains(extension)) {
      log('Invalid image format: $extension');
      return false;
    }

    return true;
  }

  /// Get optimized URL from public ID
  String getOptimizedUrl(
    String publicId, {
    int? width,
    int? height,
    String? transformation,
  }) {
    return CloudinaryConstants.getOptimizedUrl(
      publicId,
      width: width,
      height: height,
      transformation: transformation,
    );
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String publicId) {
    return CloudinaryConstants.getThumbnailUrl(publicId);
  }

  /// Get responsive URLs
  Map<String, String> getResponsiveUrls(String publicId) {
    return CloudinaryConstants.getResponsiveUrls(publicId);
  }
}