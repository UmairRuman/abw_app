// lib/features/auth/data/collections/phone_verification_collection.dart

import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneVerificationCollection {
  // Singleton pattern
  static final PhoneVerificationCollection instance = 
      PhoneVerificationCollection._internal();
  PhoneVerificationCollection._internal();
  
  factory PhoneVerificationCollection() {
    return instance;
  }

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Store verification IDs temporarily
  final Map<String, String> _verificationIds = {};

  /// Send OTP to phone number
  Future<String?> sendOTP(String phoneNumber) async {
    try {
      String? verificationId;
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        
        verificationCompleted: (PhoneAuthCredential credential) async {
          log('Auto verification completed');
          // Auto-retrieval of OTP (Android only)
        },
        
        verificationFailed: (FirebaseAuthException e) {
          log('Verification failed: ${e.code} - ${e.message}');
          throw Exception('Failed to send OTP: ${e.message}');
        },
        
        codeSent: (String verId, int? resendToken) {
          log('OTP sent successfully. VerificationId: $verId');
          verificationId = verId;
          _verificationIds[phoneNumber] = verId;
        },
        
        codeAutoRetrievalTimeout: (String verId) {
          log('Auto retrieval timeout');
          verificationId = verId;
        },
      );

      // Wait a bit for codeSent to be called
      await Future.delayed(const Duration(seconds: 2));
      
      if (verificationId == null) {
        verificationId = _verificationIds[phoneNumber];
      }

      return verificationId;
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth Error sending OTP: ${e.code} - ${e.message}');
      
      // Handle specific error codes
      switch (e.code) {
        case 'invalid-phone-number':
          throw Exception('Invalid phone number format');
        case 'too-many-requests':
          throw Exception('Too many requests. Please try again later');
        case 'quota-exceeded':
          throw Exception('SMS quota exceeded. Please try again later');
        default:
          throw Exception('Failed to send OTP: ${e.message}');
      }
    } catch (e) {
      log('Error sending OTP: ${e.toString()}');
      throw Exception('Failed to send OTP');
    }
  }

  /// Verify OTP code
  Future<bool> verifyOTP(String verificationId, String smsCode) async {
    try {
      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Verify credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        log('OTP verified successfully');
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth Error verifying OTP: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'invalid-verification-code':
          throw Exception('Invalid OTP code');
        case 'session-expired':
          throw Exception('OTP expired. Please request a new one');
        default:
          throw Exception('Failed to verify OTP: ${e.message}');
      }
    } catch (e) {
      log('Error verifying OTP: ${e.toString()}');
      throw Exception('Failed to verify OTP');
    }
  }

  /// Update user document with verified phone
  Future<bool> updateUserPhoneVerification(
    String userId,
    String phoneNumber,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'phone': phoneNumber,
        'isPhoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      log('User phone verification updated: $userId');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Error updating phone verification: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Error updating phone verification: ${e.toString()}');
      return false;
    }
  }

  /// Check if phone is already verified
  Future<bool> isPhoneVerified(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        return doc.data()!['isPhoneVerified'] as bool? ?? false;
      }
      
      return false;
    } catch (e) {
      log('Error checking phone verification: ${e.toString()}');
      return false;
    }
  }

  /// Get stored verification ID
  String? getVerificationId(String phoneNumber) {
    return _verificationIds[phoneNumber];
  }

  /// Clear verification ID
  void clearVerificationId(String phoneNumber) {
    _verificationIds.remove(phoneNumber);
  }
}