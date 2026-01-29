// lib/core/constants/api_constants.dart

class ApiConstants {
  ApiConstants._();

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String notificationsCollection = 'notifications';
  static const String settingsCollection = 'settings';
  
  // Firebase Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String postImagesPath = 'post_images';
  static const String documentsPath = 'documents';
  static const String thumbnailsPath = 'thumbnails';
  
  // Cloudinary (if needed later)
  static const String cloudinaryCloudName = 'your_cloud_name';
  static const String cloudinaryUploadPreset = 'your_preset';
  static const String cloudinaryApiKey = 'your_api_key';
  
  // External APIs (if any)
  static const String baseUrl = 'https://api.example.com';
  static const String apiVersion = 'v1';
  
  // API Endpoints
  static String get usersEndpoint => '$baseUrl/$apiVersion/users';
  static String get authEndpoint => '$baseUrl/$apiVersion/auth';
  
  // Headers
  static const String contentType = 'application/json';
  static const String authHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
  
  // Status Codes
  static const int successCode = 200;
  static const int createdCode = 201;
  static const int noContentCode = 204;
  static const int badRequestCode = 400;
  static const int unauthorizedCode = 401;
  static const int forbiddenCode = 403;
  static const int notFoundCode = 404;
  static const int serverErrorCode = 500;
}