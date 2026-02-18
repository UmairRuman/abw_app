// lib/features/auth/data/services/firebase_otp_service.dart
// CREATE THIS NEW FILE:

import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseOTPService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  // Send OTP
  Future<bool> sendOTP(
    String phoneNumber, {
    required Function(String error) onError,
    required Function() onCodeSent,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);

      log('📱 Sending OTP to: $formattedPhone');
      log("phoneNumber: $phoneNumber");

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),

        // Code sent successfully
        verificationCompleted: (PhoneAuthCredential credential) async {
          log('✅ Auto-verification completed');
        },

        // Verification failed
        verificationFailed: (FirebaseAuthException e) {
          log('❌ Verification failed: ${e.message}');
          onError(e.message ?? 'Verification failed');
        },

        // Code sent to phone
        codeSent: (String verificationId, int? resendToken) {
          log('✅ OTP sent! Verification ID: $verificationId');
          _verificationId = verificationId;
          onCodeSent();
        },

        // Code auto-retrieval timeout
        codeAutoRetrievalTimeout: (String verificationId) {
          log('⏱️ Auto-retrieval timeout');
          _verificationId = verificationId;
        },
      );

      return true;
    } catch (e) {
      log('❌ Error sending OTP: $e');
      onError(e.toString());
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String otpCode) async {
    try {
      if (_verificationId == null) {
        log('❌ No verification ID');
        return false;
      }

      log('🔐 Verifying OTP: $otpCode');

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        log('✅ OTP verified! User: ${userCredential.user!.uid}');

        // Sign out from Firebase (we only use it for OTP verification)
        await _auth.signOut();

        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      log('❌ Verification error: ${e.message}');
      return false;
    } catch (e) {
      log('❌ Error: $e');
      return false;
    }
  }

  // Format phone to E.164
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('0')) {
        cleaned = '+92${cleaned.substring(1)}';
      } else if (cleaned.startsWith('92')) {
        cleaned = '+$cleaned';
      } else {
        cleaned = '+92$cleaned';
      }
    }

    log('📞 Formatted: $phone → $cleaned');
    return cleaned;
  }
}
