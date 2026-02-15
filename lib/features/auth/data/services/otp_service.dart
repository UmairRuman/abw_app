// lib/features/auth/data/services/otp_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class OTPService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Send OTP via SMS
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      // Format phone with country code if not present
      final formattedPhone = _formatPhoneNumber(phoneNumber);

      await _supabase.auth.signInWithOtp(
        phone: formattedPhone,
        shouldCreateUser: false, // We create user via Firebase
      );

      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String phoneNumber, String otpCode) async {
    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);

      final response = await _supabase.auth.verifyOTP(
        phone: formattedPhone,
        token: otpCode,
        type: OtpType.sms,
      );

      // Sign out from Supabase immediately (we only use it for OTP)
      await _supabase.auth.signOut();

      return response.session != null;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Format phone number to E.164 format (e.g., +923001234567)
  String _formatPhoneNumber(String phone) {
    // Remove spaces, dashes, parentheses
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

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

    return cleaned;
  }
}
