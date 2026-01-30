// lib/core/constants/auth_constants.dart

class AuthConstants {
  AuthConstants._();

  // Admin Access Key (Store in Firebase Remote Config in production)
  static const String adminAccessKey = 'ABW_ADMIN_2024_SECURE';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String ridersCollection = 'riders';
  static const String adminsCollection = 'admins';
  static const String riderRequestsCollection = 'rider_requests';
  static const String restaurantsCollection = 'restaurants';
  static const String ordersCollection = 'orders';
  static const String categoriesCollection = 'categories';

  // User Fields
  static const String fieldUserId = 'userId';
  static const String fieldEmail = 'email';
  static const String fieldName = 'name';
  static const String fieldPhone = 'phone';
  static const String fieldRole = 'role';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldIsActive = 'isActive';
  static const String fieldProfileImage = 'profileImage';

  // Customer Specific Fields
  static const String fieldAddress = 'address';
  static const String fieldLocation = 'location';
  static const String fieldLatitude = 'latitude';
  static const String fieldLongitude = 'longitude';

  // Rider Specific Fields
  static const String fieldVehicleType = 'vehicleType';
  static const String fieldVehicleNumber = 'vehicleNumber';
  static const String fieldLicenseNumber = 'licenseNumber';
  static const String fieldIsApproved = 'isApproved';
  static const String fieldIsAvailable = 'isAvailable';
  static const String fieldRating = 'rating';
  static const String fieldTotalDeliveries = 'totalDeliveries';

  // Rider Request Fields
  static const String fieldRequestId = 'requestId';
  static const String fieldRiderId = 'riderId';
  static const String fieldStatus = 'status';
  static const String fieldRequestedAt = 'requestedAt';
  static const String fieldReviewedAt = 'reviewedAt';
  static const String fieldReviewedBy = 'reviewedBy';
  static const String fieldRejectionReason = 'rejectionReason';

  // Auth Messages
  static const String msgLoginSuccess = 'Login successful!';
  static const String msgSignupSuccess = 'Account created successfully!';
  static const String msgLogoutSuccess = 'Logged out successfully!';
  static const String msgPasswordResetSent = 'Password reset email sent!';
  static const String msgInvalidCredentials = 'Invalid email or password';
  static const String msgEmailAlreadyExists = 'Email already in use';
  static const String msgWeakPassword = 'Password is too weak';
  static const String msgInvalidEmail = 'Invalid email address';
  static const String msgUserNotFound = 'User not found';
  static const String msgAdminKeyRequired = 'Admin access key is required';
  static const String msgInvalidAdminKey = 'Invalid admin access key';
  static const String msgRiderRequestSent = 'Access request sent to admin';
  static const String msgRiderNotApproved = 'Your rider account is pending approval';
}