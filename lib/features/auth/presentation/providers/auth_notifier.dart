// lib/features/auth/presentation/providers/auth_notifier.dart
// UPDATED: FCM token saving in background (non-blocking)

import 'dart:developer';

import 'package:abw_app/features/auth/data/models/admin_model.dart';
import 'package:abw_app/features/auth/data/models/customer_model.dart';
import 'package:abw_app/features/auth/data/models/rider_model.dart';
import 'package:abw_app/features/auth/domain/entities/user_entity.dart';
import 'package:abw_app/features/auth/domain/usecases/create_admin_usecase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/rider_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_with_email_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/signup_customer_usecase.dart';
import '../../domain/usecases/signup_rider_usecase.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginWithEmailUseCase _loginWithEmailUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final SignUpCustomerUseCase _signUpCustomerUseCase;
  final SignUpRiderUseCase _signUpRiderUseCase;
  final SendPasswordResetUseCase _sendPasswordResetUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CreateAdminUseCase _createAdminUseCase;

  AuthNotifier({
    required LoginWithEmailUseCase loginWithEmailUseCase,
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required SignUpCustomerUseCase signUpCustomerUseCase,
    required SignUpRiderUseCase signUpRiderUseCase,
    required SendPasswordResetUseCase sendPasswordResetUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required CreateAdminUseCase createAdminUseCase,
  }) : _loginWithEmailUseCase = loginWithEmailUseCase,
       _loginWithGoogleUseCase = loginWithGoogleUseCase,
       _signUpCustomerUseCase = signUpCustomerUseCase,
       _signUpRiderUseCase = signUpRiderUseCase,
       _sendPasswordResetUseCase = sendPasswordResetUseCase,
       _logoutUseCase = logoutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _createAdminUseCase = createAdminUseCase,
       super(const AuthInitial()) {
    _checkAuthStatus();
  }

  // ========================================================================
  // HELPER METHOD: Save FCM Token in Background (Non-Blocking)
  // ========================================================================

  /// Save FCM token in background without blocking UI updates
  Future<void> _saveFCMTokenInBackground(String userId, String role) async {
    try {
      await NotificationService().saveFCMTokenToFirestore(
        userId,
        role.toLowerCase(),
      );
      log('✅ FCM token saved for $role: $userId');
    } catch (e) {
      log('⚠️ Failed to save FCM token: $e');
      // Don't rethrow - this is a background operation
    }
  }

  // ========================================================================
  // CREATE ADMIN
  // ========================================================================

  /// ✅ FIXED: Create admin with FCM token
  Future<void> createAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String accessKey,
    List<String> permissions = const [],
  }) async {
    state = const AuthLoading();

    final result = await _createAdminUseCase(
      email: email,
      password: password,
      name: name,
      phone: phone,
      accessKey: accessKey,
      permissions: permissions,
    );

    result.fold(
      (failure) {
        state = AuthError(failure.message);
      },
      (admin) {
        log("✅ Admin created successfully: ${admin.email}");

        // ✅ Set state FIRST (synchronously)
        state = Authenticated(admin);

        // ✅ Save FCM token in background
        _saveFCMTokenInBackground(admin.id, 'admin');
      },
    );
  }

  // ========================================================================
  // REFRESH USER
  // ========================================================================

  Future<void> refreshUser() async {
    final currentState = state;

    if (currentState is! Authenticated &&
        currentState is! RiderPendingApproval) {
      return;
    }

    try {
      log('🔄 Refreshing user...');

      final userId =
          currentState is Authenticated
              ? (currentState as Authenticated).user.id
              : (currentState as RiderPendingApproval).user.id;

      final role =
          currentState is Authenticated
              ? (currentState as Authenticated).user.role
              : (currentState as RiderPendingApproval).user.role;

      log('   User ID: $userId, Role: $role');

      // Determine correct collection
      final collection =
          role == UserRole.rider ? 'riders' : role.collectionName;
      log('   Reading from collection: $collection');

      final doc =
          await FirebaseFirestore.instance
              .collection(collection)
              .doc(userId)
              .get();

      if (!doc.exists) {
        log('❌ Document not found in $collection');
        return;
      }

      final userData = {'id': userId, ...doc.data()!};

      switch (role) {
        case UserRole.customer:
          state = Authenticated(CustomerModel.fromJson(userData));
          break;
        case UserRole.admin:
          state = Authenticated(AdminModel.fromJson(userData));
          break;
        case UserRole.rider:
          final rider = RiderModel.fromJson(userData);
          log('   isApproved: ${rider.isApproved}');

          if (!rider.isApproved) {
            state = RiderPendingApproval(rider);
          } else {
            state = Authenticated(rider);
          }
          break;
      }

      log('✅ User refreshed: ${state.runtimeType}');
    } catch (e) {
      log('❌ refreshUser error: $e');
    }
  }

  // ========================================================================
  // CHECK AUTH STATUS (ON APP STARTUP)
  // ========================================================================

  /// ✅ FIXED: Check current auth status on initialization
  Future<void> _checkAuthStatus() async {
    state = const AuthLoading();

    final result = await _getCurrentUserUseCase();

    result.fold(
      (failure) {
        state = const Unauthenticated();
      },
      (user) {
        if (user == null) {
          state = const Unauthenticated();
          return;
        }

        log("✅ User found on startup: ${user.email} (${user.role.name})");

        // ✅ Set state FIRST
        if (user.role == UserRole.rider) {
          final rider = user as RiderEntity;
          if (!rider.isApproved) {
            state = RiderPendingApproval(rider);
          } else {
            state = Authenticated(rider);
          }
        } else {
          state = Authenticated(user);
        }

        // ✅ Refresh FCM token in background
        _saveFCMTokenInBackground(user.id, user.role.name);
      },
    );
  }

  // ========================================================================
  // LOGIN WITH EMAIL
  // ========================================================================

  /// ✅ FIXED: Login with email and password
  Future<void> loginWithEmail({
    required String email,
    required String password,
    required UserRole role,
    String? adminKey,
  }) async {
    state = const AuthLoading();

    final result = await _loginWithEmailUseCase(
      email: email,
      password: password,
      role: role,
      adminKey: adminKey,
    );

    result.fold(
      (failure) {
        state = AuthError(failure.message);
      },
      (user) {
        log("✅ Email login successful for ${user.email}");

        // ✅ Set state FIRST (synchronously)
        if (user.role == UserRole.rider) {
          final rider = user as RiderEntity;
          if (!rider.isApproved) {
            state = RiderPendingApproval(rider);
          } else {
            state = Authenticated(rider);
          }
        } else {
          state = Authenticated(user);
        }

        // ✅ Save FCM token in background
        _saveFCMTokenInBackground(user.id, role.name);
      },
    );
  }

  // ========================================================================
  // LOGIN WITH GOOGLE
  // ========================================================================

  /// ✅ FIXED: Login with Google
  Future<void> loginWithGoogle() async {
    state = const AuthLoading();

    final result = await _loginWithGoogleUseCase();

    result.fold(
      (failure) {
        state = AuthError(failure.message);
      },
      (user) {
        log("✅ Google login successful for ${user.email}");

        // ✅ Set state FIRST (synchronously)
        state = Authenticated(user);

        // ✅ Save FCM token in background
        _saveFCMTokenInBackground(user.id, user.role.name);
      },
    );
  }

  // ========================================================================
  // SIGN UP AS CUSTOMER
  // ========================================================================

  /// ✅ FIXED: Sign up as customer
  Future<void> signUpCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    state = const AuthLoading();

    final result = await _signUpCustomerUseCase(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );

    result.fold(
      (failure) {
        state = AuthError(failure.message);
      },
      (user) {
        log("✅ Customer signup successful for ${user.email}");

        // ✅ Set state FIRST (synchronously)
        state = Authenticated(user);

        // ✅ Save FCM token in background
        _saveFCMTokenInBackground(user.id, 'customer');
      },
    );
  }

  // ========================================================================
  // SIGN UP AS RIDER
  // ========================================================================

  /// ✅ FIXED: Sign up as rider
  Future<void> signUpRider({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleNumber,
    String? licenseNumber,
  }) async {
    state = const AuthLoading();

    final result = await _signUpRiderUseCase(
      email: email,
      password: password,
      name: name,
      phone: phone,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      licenseNumber: licenseNumber,
    );

    result.fold(
      (failure) {
        state = AuthError(failure.message);
      },
      (user) {
        log("✅ Rider signup successful for ${user.email}");

        // ✅ Set state FIRST (synchronously)
        state = RiderPendingApproval(user);

        // ✅ Save FCM token in background
        _saveFCMTokenInBackground(user.id, 'rider');
      },
    );
  }

  // ========================================================================
  // PASSWORD RESET
  // ========================================================================

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AuthLoading();

    final result = await _sendPasswordResetUseCase(email);

    result.fold(
      (failure) {
        state = AuthError(failure.message);
      },
      (_) {
        state = const AuthInitial();
      },
    );
  }

  // ========================================================================
  // LOGOUT
  // ========================================================================

  /// Logout
  Future<void> logout() async {
    state = const AuthLoading();

    final result = await _logoutUseCase();

    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const Unauthenticated(),
    );
  }

  // ========================================================================
  // CLEAR ERROR
  // ========================================================================

  /// Clear error state
  void clearError() {
    if (state is AuthError) {
      state = const Unauthenticated();
    }
  }
}
