// lib/features/auth/data/services/otp_service.dart

import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

class OTPService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Send OTP via SMS
  Future<OTPResult> sendOTP(String phoneNumber) async {
    try {
      // Format phone with country code if not present
      final formattedPhone = _formatPhoneNumber(phoneNumber);

      log('📱 Attempting to send OTP to: $formattedPhone');

      // ✅ FIX: Use signUp instead of signInWithOtp
      final response = await _supabase.auth.signUp(
        phone: formattedPhone,
        password: 'dummy-password-${DateTime.now().millisecondsSinceEpoch}',
      );
      log('✅ OTP Response: ${response.user?.phone}');
      log('✅ OTP sent successfully to: $formattedPhone');
      return OTPResult(success: true, message: 'OTP sent successfully');
    } on AuthException catch (e) {
      // ✅ Supabase-specific auth errors
      log('❌ Supabase Auth Error: ${e.message}');
      log('   Status Code: ${e.statusCode}');

      String userMessage;
      switch (e.statusCode) {
        case '400':
          userMessage = 'Invalid phone number format';
          break;
        case '429':
          userMessage = 'Too many requests. Please try again later';
          break;
        case '500':
          userMessage = 'Server error. Please try again';
          break;
        default:
          userMessage = e.message ?? 'Failed to send OTP';
      }

      return OTPResult(success: false, message: userMessage);
    } catch (e) {
      // ✅ Generic errors
      log('❌ Unexpected Error: $e');
      log('   Error Type: ${e.runtimeType}');

      return OTPResult(
        success: false,
        message: 'Failed to send OTP: ${e.toString()}',
      );
    }
  }

  // Verify OTP
  Future<OTPResult> verifyOTP(String phoneNumber, String otpCode) async {
    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);

      log('📱 Attempting to verify OTP for: $formattedPhone');
      log('   OTP Code: $otpCode');

      final response = await _supabase.auth.verifyOTP(
        phone: formattedPhone,
        token: otpCode,
        type: OtpType.sms,
      );

      if (response.session != null) {
        log('✅ OTP verified successfully');
        // Sign out from Supabase immediately (we only use it for OTP)
        await _supabase.auth.signOut();
        return OTPResult(success: true, message: 'Phone verified successfully');
      } else {
        log('❌ No session returned after OTP verification');
        return OTPResult(success: false, message: 'Invalid OTP');
      }
    } on AuthException catch (e) {
      log('❌ Supabase Auth Error during verification: ${e.message}');

      String userMessage;
      if (e.message?.contains('expired') ?? false) {
        userMessage = 'OTP has expired. Please request a new one';
      } else if (e.message?.contains('invalid') ?? false) {
        userMessage = 'Invalid OTP code';
      } else {
        userMessage = e.message ?? 'Verification failed';
      }

      return OTPResult(success: false, message: userMessage);
    } catch (e) {
      log('❌ Unexpected Error during verification: $e');
      return OTPResult(
        success: false,
        message: 'Verification failed: ${e.toString()}',
      );
    }
  }

  // Format phone number to E.164 format (e.g., +923001234567)
  String _formatPhoneNumber(String phone) {
    // Remove spaces, dashes, parentheses
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    log('🔧 Formatting phone: $phone -> $cleaned');

    // Add +92 if not present (Pakistan)
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('0')) {
        cleaned = '+92${cleaned.substring(1)}';
      } else if (cleaned.startsWith('92')) {
        cleaned = '+$cleaned';
      } else {
        cleaned = '+92$cleaned';
      }
    }

    log('   Final format: $cleaned');
    return cleaned;
  }
}

// ✅ Result class for better error handling
class OTPResult {
  final bool success;
  final String message;

  OTPResult({required this.success, required this.message});
}
