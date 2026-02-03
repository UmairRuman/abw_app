// lib/features/auth/data/datasources/auth_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide FirebaseException;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/auth_constants.dart';
import '../../../../core/errors/exceptions.dart' hide FirebaseException;
import '../../../../shared/enums/user_role.dart';
import '../../../../shared/enums/rider_request_status.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  /// Get current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ============================================================
  // AUTHENTICATION OPERATIONS
  // ============================================================

  /// Login with email and password
  Future<UserCredential> loginWithEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  /// Login with Google
  Future<UserCredential> loginWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        throw AuthException(message: 'Google sign-in cancelled by user');
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException(message: 'Failed to logout: ${e.toString()}');
    }
  }

  // ============================================================
  // FIRESTORE OPERATIONS
  // ============================================================

  /// Create user document in Firestore
  Future<void> createUserDocument({
    required String uid,
    required Map<String, dynamic> userData,
    required UserRole role,
  }) async {
    try {
      await _firestore
          .collection(role.collectionName)
          .doc(uid)
          .set(userData);
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: e.message ?? 'Failed to create user document',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to create user document: ${e.toString()}',
      );
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>> getUserData(
    String uid,
    UserRole role,
  ) async {
    try {
      final doc =
          await _firestore.collection(role.collectionName).doc(uid).get();

      if (!doc.exists) {
        throw NotFoundException(message: 'User not found in ${role.name} collection');
      }

      final data = doc.data();
      if (data == null) {
        throw NotFoundException(message: 'User data is null');
      }

      return data;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: e.message ?? 'Failed to get user data',
        code: e.code,
      );
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to get user data: ${e.toString()}',
      );
    }
  }

  /// Update user data in Firestore
  Future<void> updateUserData({
    required String uid,
    required UserRole role,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Add updatedAt timestamp
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(role.collectionName).doc(uid).update(data);
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: e.message ?? 'Failed to update user data',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to update user data: ${e.toString()}',
      );
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String uid, UserRole role) async {
    try {
      // Delete Firestore document
      await _firestore.collection(role.collectionName).doc(uid).delete();

      // Delete Firebase Auth account
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: e.message ?? 'Failed to delete account',
        code: e.code,
      );
    } catch (e) {
      throw AuthException(message: 'Failed to delete account: ${e.toString()}');
    }
  }
   

   // lib/features/auth/data/datasources/auth_remote_datasource.dart

// ADD these methods to the existing AuthRemoteDataSource class:

  // ============================================================
  // USER MANAGEMENT OPERATIONS (For Admin)
  // ============================================================

  /// Get all users from a specific collection
  Future<List<Map<String, dynamic>>> getAllUsers(UserRole role) async {
    try {
      final snapshot = await _firestore
          .collection(role.collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Include document ID
            return data;
          })
          .toList();
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: e.message ?? 'Failed to get users',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to get users: ${e.toString()}',
      );
    }
  }

  /// Get all customers
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    return await getAllUsers(UserRole.customer);
  }

  /// Get all riders
  Future<List<Map<String, dynamic>>> getAllRiders() async {
    return await getAllUsers(UserRole.rider);
  }

  /// Get user count by role
  Future<int> getUserCount(UserRole role) async {
    try {
      final snapshot = await _firestore
          .collection(role.collectionName)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get all pending rider requests
  Future<List<Map<String, dynamic>>> getPendingRiderRequests() async {
    try {
      final snapshot = await _firestore
          .collection(AuthConstants.riderRequestsCollection)
          .where(AuthConstants.fieldStatus,
              isEqualTo: RiderRequestStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data[AuthConstants.fieldRequestId] = doc.id;
            return data;
          })
          .toList();
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: e.message ?? 'Failed to get pending requests',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to get pending requests: ${e.toString()}',
      );
    }
  }

  /// Search users by email or name
  Future<List<Map<String, dynamic>>> searchUsers(
    UserRole role,
    String query,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(role.collectionName)
          .get();

      final lowerQuery = query.toLowerCase();
      
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final name = (data['name'] as String?)?.toLowerCase() ?? '';
            final email = (data['email'] as String?)?.toLowerCase() ?? '';
            return name.contains(lowerQuery) || email.contains(lowerQuery);
          })
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();
    } catch (e) {
      return [];
    }
  }
  // ============================================================
  // RIDER REQUEST OPERATIONS
  // ============================================================

  /// Create rider request
  Future<String> createRiderRequest(Map<String, dynamic> requestData) async {
    try {
      final docRef = await _firestore
          .collection(AuthConstants.riderRequestsCollection)
          .add(requestData);
      
      return docRef.id;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: e.message ?? 'Failed to create rider request',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to create rider request: ${e.toString()}',
      );
    }
  }

  /// Get rider request by rider ID
  Future<Map<String, dynamic>?> getRiderRequest(String riderId) async {
    try {
      final query = await _firestore
          .collection(AuthConstants.riderRequestsCollection)
          .where(AuthConstants.fieldRiderId, isEqualTo: riderId)
          .where(AuthConstants.fieldStatus,
              isEqualTo: RiderRequestStatus.pending.name)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final data = query.docs.first.data();
      data[AuthConstants.fieldRequestId] = query.docs.first.id;
      return data;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: e.message ?? 'Failed to get rider request',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to get rider request: ${e.toString()}',
      );
    }
  }

  /// Update rider request status
  Future<void> updateRiderRequestStatus({
    required String requestId,
    required RiderRequestStatus status,
    String? reviewedBy,
    String? rejectionReason,
  }) async {
    try {
      final data = <String, dynamic>{
        AuthConstants.fieldStatus: status.name,
        'reviewedAt': FieldValue.serverTimestamp(),
        if (reviewedBy != null) 'reviewedBy': reviewedBy,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };

      await _firestore
          .collection(AuthConstants.riderRequestsCollection)
          .doc(requestId)
          .update(data);
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: e.message ?? 'Failed to update rider request status',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to update rider request status: ${e.toString()}',
      );
    }
  }

  // ============================================================
  // UTILITY OPERATIONS
  // ============================================================

  /// Check if email is already registered
  /// SECURE METHOD - Checks Firestore instead of deprecated fetchSignInMethodsForEmail
  /// Note: This only checks if email exists in our Firestore collections
  /// It won't detect accounts created through Google Sign-In that haven't been saved yet
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Check in all user collections
      for (final role in UserRole.values) {
        final query = await _firestore
            .collection(role.collectionName)
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        
        if (query.docs.isNotEmpty) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      // On error, return false to allow signup attempt
      // Firebase Auth will handle the actual duplicate check
      return false;
    }
  }

  /// Alternative: Let Firebase Auth handle duplicate email detection
  /// This is the RECOMMENDED approach - just try to create account
  /// If email exists, Firebase Auth will throw 'email-already-in-use' error
  /// This prevents email enumeration attacks
  
  /// Check if user exists in a specific collection
  Future<bool> userExistsInCollection(String uid, String collection) async {
    try {
      final doc = await _firestore.collection(collection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // ERROR MESSAGE MAPPING
  // ============================================================

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification ID';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}