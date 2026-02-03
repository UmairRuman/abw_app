// lib/core/constants/cloudinary_constants.dart

class CloudinaryConstants {
  CloudinaryConstants._();

  // Cloudinary Configuration
  // TODO: Replace with your actual Cloudinary credentials
  static const String cloudName = 'dksognlzq'; // e.g., 'abw-services'
  static const String apiKey = '352391828741146';
  static const String apiSecret = 'EbnVaQpYx4_q6xQyUvE9UdX_as0';
  static const String uploadPreset = 'abw_app'; // Create this in Cloudinary dashboard

  // Base URLs
  static String get uploadUrl => 
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  
  static String get baseImageUrl => 
      'https://res.cloudinary.com/$cloudName/image/upload';

  // Folder structure
  static const String categoryIconsFolder = 'categories/icons';
  static const String storeLogosFolder = 'stores/logos';
  static const String storeBannersFolder = 'stores/banners';
  static const String storeImagesFolder = 'stores/images';
  static const String productImagesFolder = 'products/images';
  static const String productThumbnailsFolder = 'products/thumbnails';
  static const String profileImagesFolder = 'profiles';

  // Default transformations
  static const String categoryIconTransform = 'w_200,h_200,c_fill,q_auto,f_auto';
  static const String storeLogoTransform = 'w_300,h_300,c_fill,q_auto,f_auto';
  static const String storeBannerTransform = 'w_1200,h_400,c_fill,q_auto,f_auto';
  static const String productImageTransform = 'w_800,h_800,c_fill,q_auto,f_auto';
  static const String productThumbnailTransform = 'w_300,h_300,c_fill,q_auto,f_auto';
  static const String profileImageTransform = 'w_400,h_400,c_fill,q_auto,f_auto';

  // Quality presets
  static const String highQuality = 'q_90';
  static const String mediumQuality = 'q_80';
  static const String lowQuality = 'q_60';
  static const String autoQuality = 'q_auto';

  // Format presets
  static const String autoFormat = 'f_auto'; // Automatically choose best format
  static const String webp = 'f_webp';
  static const String jpg = 'f_jpg';
  static const String png = 'f_png';

  /// Generate optimized URL
  static String getOptimizedUrl(
    String publicId, {
    int? width,
    int? height,
    String? transformation,
    String quality = autoQuality,
    String format = autoFormat,
  }) {
    final transforms = <String>[];
    
    if (width != null) transforms.add('w_$width');
    if (height != null) transforms.add('h_$height');
    if (transformation != null) {
      transforms.add(transformation);
    } else {
      transforms.addAll(['c_fill', quality, format]);
    }

    final transformString = transforms.join(',');
    return '$baseImageUrl/$transformString/$publicId';
  }

  /// Generate thumbnail URL
  static String getThumbnailUrl(String publicId) {
    return getOptimizedUrl(
      publicId,
      width: 300,
      height: 300,
      transformation: 'c_thumb',
    );
  }

  /// Generate responsive URLs
  static Map<String, String> getResponsiveUrls(String publicId) {
    return {
      'thumbnail': getOptimizedUrl(publicId, width: 300, height: 300),
      'small': getOptimizedUrl(publicId, width: 600, height: 600),
      'medium': getOptimizedUrl(publicId, width: 1000, height: 1000),
      'large': getOptimizedUrl(publicId, width: 1500, height: 1500),
    };
  }
}