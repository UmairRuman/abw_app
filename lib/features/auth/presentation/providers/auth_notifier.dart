// lib/features/auth/presentation/providers/auth_notifier.dart

import 'dart:developer';
import 'dart:io';

import 'package:abw_app/features/auth/data/models/admin_model.dart';
import 'package:abw_app/features/auth/data/models/customer_model.dart';
import 'package:abw_app/features/auth/data/models/rider_model.dart';
import 'package:abw_app/features/auth/domain/entities/customer_entity.dart';
import 'package:abw_app/features/auth/domain/entities/user_entity.dart';
import 'package:abw_app/features/auth/domain/usecases/create_admin_usecase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  // HELPER: Correct collection name
  // ========================================================================

  /// ✅ FIX: All users (customers, riders) live in 'users' collection.
  /// Only admins have their own 'admins' collection.
  String _getUserCollection(UserRole role) {
    switch (role) {
      case UserRole.customer:
      case UserRole.rider:
        return 'users'; // ✅ FIXED — was returning 'riders' for riders
      case UserRole.admin:
        return 'admins';
    }
  }

  // ========================================================================
  // HELPER: Save FCM Token in Background
  // ========================================================================

  Future<void> _saveFCMTokenInBackground(String userId, String role) async {
    try {
      await NotificationService().saveFCMTokenToFirestore(
        userId,
        role.toLowerCase(),
      );
      log('✅ FCM token saved for $role: $userId');
    } catch (e) {
      log('⚠️ Failed to save FCM token: $e');
    }
  }

  // ========================================================================
  // CHECK AUTH STATUS (ON APP STARTUP)
  // ========================================================================

  /// ✅ FIXED: Reads directly from Firestore 'users' collection and uses
  /// the stored 'role' field to determine user type.
  ///
  /// Previously relied on _getCurrentUserUseCase which used
  /// UserRole.rider.collectionName = 'riders' — but riders are stored in
  /// 'users', so the use case couldn't find the rider document and fell
  /// back to a CustomerModel. That caused Abdullah (a rider) to be treated
  /// as a customer on every app restart.
  Future<void> _checkAuthStatus() async {
    state = const AuthLoading();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        state = const Unauthenticated();
        return;
      }

      final uid = firebaseUser.uid;

      // ── Step 1: Try 'users' collection first (customers + riders) ─────────
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = {'id': uid, ...userDoc.data()!};

        // ✅ FIX: If no role field, this is an FCM-only stub written by
        // NotificationService for an admin. Skip it and fall through to
        // admins collection check below.
        if (!data.containsKey('role') ||
            (data['role'] as String?)?.isEmpty == true) {
          log('⚠️ users doc has no role for $uid — checking admins collection');
          // intentional fall-through — do NOT return here
        } else {
          // Role field exists — handle normally
          if (!data.containsKey('isPhoneVerified')) {
            data['isPhoneVerified'] = false;
          }

          final roleStr = data['role'] as String;
          final role = UserRole.fromString(roleStr);

          log('✅ User found on startup: ${firebaseUser.email} (${role.name})');

          switch (role) {
            case UserRole.customer:
              final customer = CustomerModel.fromJson(data);
              state = Authenticated(customer);
              _saveFCMTokenInBackground(uid, 'customer');

            case UserRole.rider:
              final rider = RiderModel.fromJson(data);
              log('   isApproved: ${rider.isApproved}');
              if (!rider.isApproved) {
                state = RiderPendingApproval(rider);
              } else {
                state = Authenticated(rider);
              }
              _saveFCMTokenInBackground(uid, 'rider');

            case UserRole.admin:
              // Admin role found in users collection — handle it
              final admin = AdminModel.fromJson(data);
              state = Authenticated(admin);
              _saveFCMTokenInBackground(uid, 'admin');
          }
          return; // ✅ Only return when role was found and handled
        }
      }

      // ── Step 2: Try 'admins' collection ───────────────────────────────────
      final adminDoc = await _firestore.collection('admins').doc(uid).get();

      if (adminDoc.exists && adminDoc.data() != null) {
        final data = {'id': uid, ...adminDoc.data()!};
        log('✅ Admin found on startup: ${firebaseUser.email}');
        final admin = AdminModel.fromJson(data);
        state = Authenticated(admin);
        _saveFCMTokenInBackground(uid, 'admin');
        return;
      }

      // ── Not found anywhere ────────────────────────────────────────────────
      log(
        '⚠️ Firebase Auth session exists but no Firestore doc found for $uid',
      );
      state = const Unauthenticated();
    } catch (e) {
      log('❌ _checkAuthStatus error: $e');
      state = const Unauthenticated();
    }
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

      // ✅ FIXED: use _getUserCollection — always 'users' for customer/rider
      final collection = _getUserCollection(role);
      log('   Reading from collection: $collection for role: ${role.name}');

      final doc = await _firestore.collection(collection).doc(userId).get();

      if (!doc.exists) {
        log('❌ Document not found in $collection for $userId');
        return;
      }

      final userData = {'id': userId, ...doc.data()!};

      switch (role) {
        case UserRole.customer:
          state = Authenticated(CustomerModel.fromJson(userData));
        case UserRole.admin:
          state = Authenticated(AdminModel.fromJson(userData));
        case UserRole.rider:
          final rider = RiderModel.fromJson(userData);
          log('   isApproved: ${rider.isApproved}');
          if (!rider.isApproved) {
            state = RiderPendingApproval(rider);
          } else {
            state = Authenticated(rider);
          }
      }

      log('✅ User refreshed: ${state.runtimeType}');
    } catch (e) {
      log('❌ refreshUser error: $e');
    }
  }

  // ========================================================================
  // CREATE ADMIN
  // ========================================================================

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

    result.fold((failure) => state = AuthError(failure.message), (admin) {
      log('✅ Admin created successfully: ${admin.email}');
      state = Authenticated(admin);
      _saveFCMTokenInBackground(admin.id, 'admin');
    });
  }

  // ========================================================================
  // UPDATE PROFILE
  // ========================================================================

  Future<bool> updateProfile({
    String? name,
    String? phone,
    File? profileImage,
  }) async {
    try {
      final currentState = state;
      if (currentState is! Authenticated) {
        log('❌ User not authenticated');
        return false;
      }

      final user = currentState.user;
      log('📝 Updating profile for user: ${user.id}');

      if (name != null && (name.trim().isEmpty || name.trim().length < 3)) {
        log('❌ Invalid name: must be at least 3 characters');
        return false;
      }

      if (phone != null &&
          !RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(phone.trim())) {
        log('❌ Invalid phone number format');
        return false;
      }

      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name.trim();

      bool phoneChanged = false;
      if (phone != null && phone.trim() != user.phone) {
        updateData['phone'] = phone.trim();
        updateData['isPhoneVerified'] = false;
        phoneChanged = true;
        log('📱 Phone changed - verification required');
      }

      String? imageUrl;
      if (profileImage != null) {
        imageUrl = await _saveImageLocally(user.id, profileImage);
        if (imageUrl != null) {
          updateData['profileImage'] = imageUrl;
          log('✅ Profile image saved: $imageUrl');
        }
      }

      // ✅ FIXED: update in the correct collection
      final userCollection = _getUserCollection(user.role);
      await _firestore
          .collection(userCollection)
          .doc(user.id)
          .update(updateData);

      log('✅ Profile updated successfully');

      final updatedUser = (user as CustomerEntity).copyWith(
        name: name ?? user.name,
        phone: phone ?? user.phone,
        profileImage: imageUrl ?? user.profileImage,
        isPhoneVerified: phoneChanged ? false : null,
      );

      state = Authenticated(updatedUser);
      return true;
    } catch (e) {
      log('❌ Error updating profile: $e');
      return false;
    }
  }

  Future<String?> _uploadProfileImage(String userId, File imageFile) async {
    try {
      log('📤 Uploading profile image...');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userId.jpg');
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      log('✅ Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('❌ Error uploading image: $e');
      return null;
    }
  }

  Future<String?> _saveImageLocally(String userId, File imageFile) async {
    try {
      log('💾 Saving image locally...');
      final directory = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${directory.path}/profile_images');
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }
      final savedImage = await imageFile.copy(
        '${profileImagesDir.path}/$userId.jpg',
      );
      log('✅ Image saved locally: ${savedImage.path}');
      return savedImage.path;
    } catch (e) {
      log('❌ Error saving image locally: $e');
      return null;
    }
  }

  // ========================================================================
  // LOGIN WITH EMAIL
  // ========================================================================

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

    result.fold((failure) => state = AuthError(failure.message), (user) {
      log('✅ Email login successful for ${user.email} (${user.role.name})');
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
      _saveFCMTokenInBackground(user.id, role.name);
    });
  }

  // ========================================================================
  // LOGIN WITH GOOGLE
  // ========================================================================

  Future<void> loginWithGoogle() async {
    state = const AuthLoading();

    final result = await _loginWithGoogleUseCase();

    result.fold((failure) => state = AuthError(failure.message), (user) {
      log('✅ Google login successful for ${user.email}');
      state = Authenticated(user);
      _saveFCMTokenInBackground(user.id, user.role.name);
    });
  }

  // ========================================================================
  // SIGN UP
  // ========================================================================

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

    result.fold((failure) => state = AuthError(failure.message), (user) {
      log('✅ Customer signup: ${user.email}');
      state = Authenticated(user);
      _saveFCMTokenInBackground(user.id, 'customer');
    });
  }

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

    result.fold((failure) => state = AuthError(failure.message), (user) {
      log('✅ Rider signup: ${user.email}');
      state = RiderPendingApproval(user);
      _saveFCMTokenInBackground(user.id, 'rider');
    });
  }

  // ========================================================================
  // PASSWORD RESET / LOGOUT / CLEAR ERROR
  // ========================================================================

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AuthLoading();
    final result = await _sendPasswordResetUseCase(email);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const AuthInitial(),
    );
  }

  Future<void> logout() async {
    state = const AuthLoading();
    final result = await _logoutUseCase();
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const Unauthenticated(),
    );
  }

  void clearError() {
    if (state is AuthError) {
      state = const Unauthenticated();
    }
  }
}
