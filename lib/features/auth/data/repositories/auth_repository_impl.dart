// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/auth_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/enums/user_role.dart';
import '../../domain/entities/admin_entity.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/rider_entity.dart';
import '../../domain/entities/rider_request_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/admin_model.dart';
import '../models/customer_model.dart';
import '../models/rider_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = remoteDataSource.currentUser;
      if (user == null) return const Right(null);

      // Try to get user from each collection
      for (final role in UserRole.values) {
        try {
          final userData = await remoteDataSource.getUserData(user.uid, role);
          return Right(_parseUserData(userData, role));
        } catch (e) {
          continue;
        }
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return remoteDataSource.authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      
      for (final role in UserRole.values) {
        try {
          final userData = await remoteDataSource.getUserData(user.uid, role);
          return _parseUserData(userData, role);
        } catch (e) {
          continue;
        }
      }
      return null;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
    required UserRole role,
    String? adminKey,
  }) async {
    try {
      final credential = await remoteDataSource.loginWithEmail(email, password);
      final userData = await remoteDataSource.getUserData(credential.user!.uid, role);
      return Right(_parseUserData(userData, role));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> loginWithGoogle() async {
    try {
      final credential = await remoteDataSource.loginWithGoogle();
      final uid = credential.user!.uid;

      try {
        final userData = await remoteDataSource.getUserData(uid, UserRole.customer);
        return Right(CustomerModel.fromJson(userData));
      } catch (e) {
        // Create new customer if doesn't exist
        final customer = CustomerModel(
          id: uid,
          email: credential.user!.email!,
          name: credential.user!.displayName ?? '',
          phone: credential.user!.phoneNumber ?? '',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await remoteDataSource.createUserDocument(
          uid: uid,
          userData: customer.toJson(),
          role: UserRole.customer,
        );

        return Right(customer);
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> signUpCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final credential = await remoteDataSource.signUpWithEmail(email, password);
      final customer = CustomerModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await remoteDataSource.createUserDocument(
        uid: customer.id,
        userData: customer.toJson(),
        role: UserRole.customer,
      );

      return Right(customer);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RiderEntity>> signUpRider({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleNumber,
    String? licenseNumber,
  }) async {
    try {
      final credential = await remoteDataSource.signUpWithEmail(email, password);
      final rider = RiderModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        licenseNumber: licenseNumber,
        isApproved: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await remoteDataSource.createUserDocument(
        uid: rider.id,
        userData: rider.toJson(),
        role: UserRole.rider,
      );

      return Right(rider);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  bool verifyAdminKey(String key) {
    return key == AuthConstants.adminAccessKey;
  }

  // Helper method to parse user data
  UserEntity _parseUserData(Map<String, dynamic> data, UserRole role) {
    switch (role) {
      case UserRole.customer:
        return CustomerModel.fromJson(data);
      case UserRole.rider:
        return RiderModel.fromJson(data);
      case UserRole.admin:
        return AdminModel.fromJson(data);
    }
  }

  // Other methods (not critical for initial implementation)
  @override
  Future<Either<Failure, AdminEntity>> createAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String accessKey,
    List<String> permissions = const [],
  }) async {
    // TODO: Implement admin creation
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, RiderRequestEntity>> submitRiderRequest({
    required String riderId,
    required String riderName,
    required String riderEmail,
    required String riderPhone,
    required String vehicleType,
    required String vehicleNumber,
  }) async {
    // TODO: Implement rider request submission
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, RiderRequestEntity?>> getRiderRequest(String riderId) async {
    // TODO: Implement get rider request
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    required UserRole role,
    String? name,
    String? phone,
    String? profileImage,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    // TODO: Implement profile update
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> deleteAccount(String userId, UserRole role) async {
    // TODO: Implement account deletion
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, bool>> isEmailRegistered(String email) async {
    // TODO: Implement email check
    throw UnimplementedError();
  }
}