// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/constants/auth_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../../shared/enums/rider_request_status.dart';
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
import '../models/rider_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  // ============================================================
  // CURRENT USER & AUTH STATE
  // ============================================================

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
          // Continue to next role if not found
          continue;
        }
      }
      
      // User authenticated but no data found in any collection
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

  // ============================================================
  // LOGIN OPERATIONS
  // ============================================================

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
    required UserRole role,
    String? adminKey,
  }) async {
    try {
      // Verify admin key if logging in as admin
      if (role == UserRole.admin) {
        if (adminKey == null || !verifyAdminKey(adminKey)) {
          return const Left(
            AuthFailure(message: 'Invalid admin access key'),
          );
        }
      }

      // Authenticate with Firebase
      final credential = await remoteDataSource.loginWithEmail(email, password);
      
      // Get user data from Firestore
      final userData = await remoteDataSource.getUserData(
        credential.user!.uid,
        role,
      );

      return Right(_parseUserData(userData, role));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(AuthFailure(
        message: 'Account not found as ${role.displayName}. Please check your login type.',
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> loginWithGoogle() async {
    try {
      final credential = await remoteDataSource.loginWithGoogle();
      final uid = credential.user!.uid;

      // Try to get existing customer data
      try {
        final userData = await remoteDataSource.getUserData(
          uid,
          UserRole.customer,
        );
        return Right(CustomerModel.fromJson(userData));
      } catch (e) {
        // Create new customer if doesn't exist
        final customer = CustomerModel(
          id: uid,
          email: credential.user!.email!,
          name: credential.user!.displayName ?? 'User',
          phone: credential.user!.phoneNumber ?? '',
          profileImage: credential.user!.photoURL,
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

  // ============================================================
  // SIGNUP OPERATIONS
  // ============================================================

  @override
  Future<Either<Failure, CustomerEntity>> signUpCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Create Firebase Auth account
      final credential = await remoteDataSource.signUpWithEmail(
        email,
        password,
      );

      // Create customer entity
      final customer = CustomerModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
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
      // Create Firebase Auth account
      final credential = await remoteDataSource.signUpWithEmail(
        email,
        password,
      );

      // Create rider entity (not approved by default)
      final rider = RiderModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        licenseNumber: licenseNumber,
        isApproved: false, // Requires admin approval
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await remoteDataSource.createUserDocument(
        uid: rider.id,
        userData: rider.toJson(),
        role: UserRole.rider,
      );

      // Create rider access request
      final requestData = {
        AuthConstants.fieldRiderId: rider.id,
        'riderName': name,
        'riderEmail': email,
        'riderPhone': phone,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        AuthConstants.fieldStatus: RiderRequestStatus.pending.name,
        'requestedAt': DateTime.now(),
      };

      await remoteDataSource.createRiderRequest(requestData);

      return Right(rider);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminEntity>> createAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String accessKey,
    List<String> permissions = const [],
  }) async {
    try {
      // Verify admin key
      if (!verifyAdminKey(accessKey)) {
        return const Left(
          AuthFailure(message: 'Invalid admin access key'),
        );
      }

      // Create Firebase Auth account
      final credential = await remoteDataSource.signUpWithEmail(
        email,
        password,
      );

      // Create admin entity
      final admin = AdminModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        accessKey: accessKey,
        permissions: permissions,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await remoteDataSource.createUserDocument(
        uid: admin.id,
        userData: admin.toJson(),
        role: UserRole.admin,
      );

      return Right(admin);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  // ============================================================
  // PASSWORD & RIDER REQUESTS
  // ============================================================

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
  Future<Either<Failure, RiderRequestEntity>> submitRiderRequest({
    required String riderId,
    required String riderName,
    required String riderEmail,
    required String riderPhone,
    required String vehicleType,
    required String vehicleNumber,
  }) async {
    try {
      final requestData = {
        AuthConstants.fieldRiderId: riderId,
        'riderName': riderName,
        'riderEmail': riderEmail,
        'riderPhone': riderPhone,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        AuthConstants.fieldStatus: RiderRequestStatus.pending.name,
        'requestedAt': DateTime.now(),
      };

      final requestId = await remoteDataSource.createRiderRequest(requestData);

      final request = RiderRequestModel(
        id: requestId,
        riderId: riderId,
        riderName: riderName,
        riderEmail: riderEmail,
        riderPhone: riderPhone,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        status: RiderRequestStatus.pending,
        requestedAt: DateTime.now(),
      );

      return Right(request);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RiderRequestEntity?>> getRiderRequest(
    String riderId,
  ) async {
    try {
      final requestData = await remoteDataSource.getRiderRequest(riderId);
      
      if (requestData == null) {
        return const Right(null);
      }

      final request = RiderRequestModel.fromJson(requestData);
      return Right(request);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  // ============================================================
  // LOGOUT & UTILITIES
  // ============================================================

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
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (profileImage != null) updateData['profileImage'] = profileImage;
      if (address != null) updateData['address'] = address;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;

      await remoteDataSource.updateUserData(
        uid: userId,
        role: role,
        data: updateData,
      );

      // Get updated user data
      final userData = await remoteDataSource.getUserData(userId, role);
      return Right(_parseUserData(userData, role));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount(
    String userId,
    UserRole role,
  ) async {
    try {
      await remoteDataSource.deleteAccount(userId, role);
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailRegistered(String email) async {
    try {
      final isRegistered = await remoteDataSource.isEmailRegistered(email);
      return Right(isRegistered);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  bool verifyAdminKey(String key) {
    return key == AuthConstants.adminAccessKey;
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

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
}