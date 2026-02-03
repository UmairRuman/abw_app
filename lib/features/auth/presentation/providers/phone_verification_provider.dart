// lib/features/auth/presentation/providers/phone_verification_provider.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/phone_verification_collection.dart';

final phoneVerificationProvider = 
    NotifierProvider<PhoneVerificationNotifier, PhoneVerificationState>(
      PhoneVerificationNotifier.new,
    );

class PhoneVerificationNotifier extends Notifier<PhoneVerificationState> {
  late final PhoneVerificationCollection _collection;
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  PhoneVerificationState build() {
    _collection = PhoneVerificationCollection();
    return PhoneVerificationInitial();
  }


  /// Send OTP
  Future<void> sendOTP(String phoneNumber) async {
    state = OTPSending();
    
    try {
      final verificationId = await _collection.sendOTP(phoneNumber);
      
      if (verificationId != null) {
        state = OTPSent(verificationId: verificationId);
        
        // Start resend countdown (60 seconds)
        _startResendCountdown();
        
        log('OTP sent to: $phoneNumber');
      } else {
        state = PhoneVerificationError(error: 'Failed to send OTP');
      }
    } catch (e) {
      state = PhoneVerificationError(error: e.toString());
      log('Error in sendOTP: ${e.toString()}');
    }
  }

  /// Verify OTP
  Future<void> verifyOTP(
    String verificationId,
    String smsCode,
    String userId,
    String phoneNumber,
  ) async {
    state = OTPVerifying();
    
    try {
      final isValid = await _collection.verifyOTP(verificationId, smsCode);
      
      if (isValid) {
        // Update user document
        await _collection.updateUserPhoneVerification(userId, phoneNumber);
        
        state = PhoneVerified();
        
        // Clear verification ID
        _collection.clearVerificationId(phoneNumber);
        
        log('Phone verified successfully');
      } else {
        state = PhoneVerificationError(error: 'Invalid OTP code');
      }
    } catch (e) {
      state = PhoneVerificationError(error: e.toString());
      log('Error in verifyOTP: ${e.toString()}');
    }
  }

  /// Resend OTP
  Future<void> resendOTP(String phoneNumber) async {
    if (_resendCountdown > 0) {
      state = PhoneVerificationError(
        error: 'Please wait $_resendCountdown seconds before resending',
      );
      return;
    }

    await sendOTP(phoneNumber);
  }

  /// Start resend countdown timer
  void _startResendCountdown() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _resendCountdown--;
      
      if (_resendCountdown <= 0) {
        timer.cancel();
      }
      
      // Update state to trigger UI refresh
      if (state is OTPSent) {
        state = (state as OTPSent).copyWith(
          resendCountdown: _resendCountdown,
        );
      }
    });
  }

  /// Get resend countdown
  int getResendCountdown() {
    return _resendCountdown;
  }

  /// Can resend OTP
  bool canResend() {
    return _resendCountdown == 0;
  }

  /// Check if phone is verified
  Future<bool> isPhoneVerified(String userId) async {
    try {
      return await _collection.isPhoneVerified(userId);
    } catch (e) {
      log('Error checking phone verification: ${e.toString()}');
      return false;
    }
  }

  /// Reset state
  void reset() {
    _resendTimer?.cancel();
    _resendCountdown = 0;
    state = PhoneVerificationInitial();
  }
}

// States
abstract class PhoneVerificationState {}

class PhoneVerificationInitial extends PhoneVerificationState {}

class OTPSending extends PhoneVerificationState {}

class OTPSent extends PhoneVerificationState {
  final String verificationId;
  final int resendCountdown;

  OTPSent({
    required this.verificationId,
    this.resendCountdown = 60,
  });

  OTPSent copyWith({
    String? verificationId,
    int? resendCountdown,
  }) {
    return OTPSent(
      verificationId: verificationId ?? this.verificationId,
      resendCountdown: resendCountdown ?? this.resendCountdown,
    );
  }
}

class OTPVerifying extends PhoneVerificationState {}

class PhoneVerified extends PhoneVerificationState {}

class PhoneVerificationError extends PhoneVerificationState {
  final String error;
  
  PhoneVerificationError({required this.error});
}