// lib/features/auth/presentation/screens/phone_verification/phone_verification_screen.dart
// REPLACE ENTIRE FILE:

import 'dart:developer';

import 'package:abw_app/features/auth/data/services/firebase_otp_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String userId;

  const PhoneVerificationScreen({super.key, required this.userId});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _otpController = TextEditingController();
  final _otpService = FirebaseOTPService();

  bool _isLoading = false;
  bool _isResending = false;
  bool _codeSent = false;
  bool _isFetchingUser = true;
  int _resendCountdown = 60;
  bool _canResend = false;

  String? _phoneNumber; // ✅ STORE PHONE NUMBER
  String? _userName; // ✅ STORE USER NAME
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndSendOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // ✅ NEW: FETCH USER DATA FROM FIRESTORE
  Future<void> _fetchUserDataAndSendOTP() async {
    setState(() => _isFetchingUser = true);

    try {
      print('🔍 Fetching user data for: ${widget.userId}');

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final phone = userData['phone'] as String?;
      final name = userData['name'] as String?;

      log('🔍 User data fetched:');
      log('   Name: $name');
      log('   Phone: $phone');

      // ✅ CHECK IF PHONE IS MISSING OR EMPTY
      if (phone == null || phone.isEmpty) {
        log('⚠️ Phone number not found, redirecting to phone input');

        if (mounted) {
          // Navigate to phone input screen
          context.pushReplacement(
            '/phone-input',
            extra: {'userId': widget.userId, 'currentPhone': null},
          );
        }
        return;
      }

      setState(() {
        _phoneNumber = phone;
        _userName = name;
        _isFetchingUser = false;
      });

      // Now send OTP
      await _sendOTP();
    } catch (e) {
      log('❌ Error fetching user: $e');
      setState(() {
        _errorMessage = e.toString();
        _isFetchingUser = false;
      });
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startCountdown();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _sendOTP() async {
    if (_phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: AppColorsDark.error,
        ),
      );
      return;
    }

    setState(() => _isResending = true);

    await _otpService.sendOTP(
      _phoneNumber!,
      onError: (error) {
        if (mounted) {
          setState(() => _isResending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: AppColorsDark.error,
            ),
          );
        }
      },
      onCodeSent: () {
        if (mounted) {
          setState(() {
            _isResending = false;
            _codeSent = true;
          });
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP sent to $_phoneNumber'),
              backgroundColor: AppColorsDark.success,
            ),
          );
        }
      },
    );
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _resendCountdown = 60;
      _canResend = false;
      _otpController.clear();
    });

    await _sendOTP();
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 6-digit OTP'),
          backgroundColor: AppColorsDark.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = await _otpService.verifyOTP(_otpController.text);

      if (!isValid) {
        throw Exception('Invalid OTP');
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'isPhoneVerified': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone verified successfully! 🎉'),
            backgroundColor: AppColorsDark.success,
          ),
        );
        context.go('/customer/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SHOW ERROR STATE
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColorsDark.background,
        appBar: AppBar(
          title: Text(
            'Verify Phone Number',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          backgroundColor: AppColorsDark.surface,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: AppColorsDark.error,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Error Loading User Data',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ SHOW LOADING STATE WHILE FETCHING
    if (_isFetchingUser || _phoneNumber == null) {
      return Scaffold(
        backgroundColor: AppColorsDark.background,
        appBar: AppBar(
          title: Text(
            'Verify Phone Number',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          backgroundColor: AppColorsDark.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColorsDark.primary),
              SizedBox(height: 16.h),
              Text(
                'Loading user data...',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ MAIN VERIFICATION UI
    final defaultPinTheme = PinTheme(
      width: 56.w,
      height: 60.h,
      textStyle: AppTextStyles.headlineSmall().copyWith(
        color: AppColorsDark.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: AppColorsDark.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColorsDark.primary, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColorsDark.primary.withOpacity(0.1),
        border: Border.all(color: AppColorsDark.primary),
      ),
    );

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Verify Phone Number',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),

              // Icon
              Container(
                width: 100.w,
                height: 100.w,
                decoration: const BoxDecoration(
                  gradient: AppColorsDark.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sms_outlined,
                  color: AppColorsDark.white,
                  size: 50.sp,
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                _codeSent ? 'Enter Verification Code' : 'Sending Code...',
                style: AppTextStyles.headlineMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 12.h),

              // Subtitle
              Text(
                _codeSent
                    ? 'We sent a 6-digit code to'
                    : 'Please wait while we send the code',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              Text(
                _phoneNumber ?? '',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 40.h),

              // OTP Input
              if (_codeSent)
                Pinput(
                  controller: _otpController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  onCompleted: (pin) => _verifyOTP(),
                  autofocus: true,
                  enableSuggestions: true,
                )
              else
                const CircularProgressIndicator(color: AppColorsDark.primary),

              SizedBox(height: 32.h),

              // Resend
              if (_codeSent)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                    if (_canResend)
                      GestureDetector(
                        onTap: _resendOTP,
                        child: Text(
                          'Resend',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Resend in $_resendCountdown s',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textTertiary,
                        ),
                      ),
                  ],
                ),

              const Spacer(),

              // Verify Button
              if (_codeSent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColorsDark.white,
                              ),
                            )
                            : Text('Verify', style: AppTextStyles.button()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
