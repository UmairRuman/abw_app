// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/enums/user_role.dart';
import '../entities/admin_entity.dart';
import '../entities/customer_entity.dart';
import '../entities/rider_entity.dart';
import '../entities/rider_request_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Get current authenticated user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Stream of auth state changes
  Stream<UserEntity?> get authStateChanges;

  /// Login with email and password
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
    required UserRole role,
    String? adminKey,
  });

  /// Login with Google
  Future<Either<Failure, CustomerEntity>> loginWithGoogle();

  /// Sign up customer
  Future<Either<Failure, CustomerEntity>> signUpCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
  });

  /// Sign up rider (creates pending request)
  Future<Either<Failure, RiderEntity>> signUpRider({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleNumber,
    String? licenseNumber,
  });

  /// Create admin (internal use only)
  Future<Either<Failure, AdminEntity>> createAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String accessKey,
    List<String> permissions = const [],
  });

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Submit rider access request
  Future<Either<Failure, RiderRequestEntity>> submitRiderRequest({
    required String riderId,
    required String riderName,
    required String riderEmail,
    required String riderPhone,
    required String vehicleType,
    required String vehicleNumber,
  });

  /// Get rider request by rider ID
  Future<Either<Failure, RiderRequestEntity?>> getRiderRequest(String riderId);

  /// Logout
  Future<Either<Failure, void>> logout();

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    required UserRole role,
    String? name,
    String? phone,
    String? profileImage,
    String? address,
    double? latitude,
    double? longitude,
  });

  /// Delete account
  Future<Either<Failure, void>> deleteAccount(String userId, UserRole role);

  /// Check if email exists
  Future<Either<Failure, bool>> isEmailRegistered(String email);

  /// Verify admin access key
  bool verifyAdminKey(String key);
}