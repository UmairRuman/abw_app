// lib/features/auth/presentation/screens/phone_verification/phone_verification_screen.dart

import 'package:abw_app/features/auth/data/services/otp_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String userId;
  final String phoneNumber;

  const PhoneVerificationScreen({
    super.key,
    required this.userId,
    required this.phoneNumber,
  });

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen>
    with CodeAutoFill {
  final _otpController = TextEditingController();
  final _otpService = OTPService();

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _sendOTP();
    _startCountdown();
    _listenForCode(); // ✅ Listen for SMS autofill
  }

  @override
  void dispose() {
    _otpController.dispose();
    cancel(); // Cancel SMS listener
    super.dispose();
  }

  // ✅ SMS AUTOFILL LISTENER
  void _listenForCode() async {
    await SmsAutoFill().listenForCode();
  }

  @override
  void codeUpdated() {
    // ✅ AUTOMATICALLY CALLED WHEN SMS RECEIVED
    if (code != null && code!.length == 6) {
      setState(() {
        _otpController.text = code!;
      });
      _verifyOTP(); // Auto-verify
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
    setState(() => _isResending = true);

    final success = await _otpService.sendOTP(widget.phoneNumber);

    if (mounted) {
      setState(() => _isResending = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${widget.phoneNumber}'),
            backgroundColor: AppColorsDark.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send OTP. Please try again.'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    _startCountdown();
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
      // Verify OTP with Supabase
      final isValid = await _otpService.verifyOTP(
        widget.phoneNumber,
        _otpController.text,
      );

      if (!isValid) {
        throw Exception('Invalid OTP');
      }

      // Update Firestore user to mark phone as verified
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

        // Navigate to customer home
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
                'Enter Verification Code',
                style: AppTextStyles.headlineMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 12.h),

              // Subtitle
              Text(
                'We sent a 6-digit code to',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              Text(
                widget.phoneNumber,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 40.h),

              // OTP Input with Pinput
              Pinput(
                controller: _otpController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                onCompleted: (pin) => _verifyOTP(),
                autofocus: true,
                enableSuggestions: true,
                // ✅ No androidSmsAutofillMethod needed - works by default
              ),

              SizedBox(height: 32.h),

              // Resend OTP
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
