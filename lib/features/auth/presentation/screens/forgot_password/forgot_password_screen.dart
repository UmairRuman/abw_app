// lib/features/auth/presentation/screens/forgot_password/forgot_password_screen.dart

import 'package:abw_app/core/theme/colors/app_colors_dark.dart';
import 'package:abw_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  await ref.read(authProvider.notifier).sendPasswordResetEmail(
    _emailController.text.trim(),
  );

  if (mounted) {
    setState(() => _isLoading = false);
  }

  final authState = ref.read(authProvider);
  
  if (authState is AuthError) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.message),
          backgroundColor: AppColorsDark.error,
        ),
      );
    }
  } else {
    // Success
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: AppColorsDark.success,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go('/login');
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorsDark.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),

          // Icon
          Container(
            width: 80.w,
            height: 80.w,
            decoration: const BoxDecoration(
              color: AppColorsDark.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset,
              size: 40.sp,
              color: AppColorsDark.primary,
            ),
          ),

          SizedBox(height: 24.h),

          // Title
          Text(
            'Forgot Password?',
             style: AppTextStyles.headlineLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
          ),

          SizedBox(height: 12.h),

          // Description
          Text(
            'No worries! Enter your email address and we\'ll send you a link to reset your password.',
            style: AppTextStyles.bodyLarge().copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: 40.h),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Invalid email address';
              }
              return null;
            },
          ),

          SizedBox(height: 32.h),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppColorsDark.white)
                  : const Text('Send Reset Link'),
            ),
          ),

          SizedBox(height: 24.h),

          // Back to Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back,
                size: 16.sp,
                color: AppColorsDark.primary,
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Back to Login',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        SizedBox(height: 60.h),

        // Success Icon
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            color: AppColorsDark.successLight.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read,
            size: 60.sp,
            color: AppColorsDark.success,
          ),
        ),

        SizedBox(height: 32.h),

        // Title
        Text(
          'Check Your Email',
          style: AppTextStyles.headlineMedium(),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 16.h),

        // Description
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'We\'ve sent a password reset link to\n${_emailController.text}',
            style: AppTextStyles.bodyLarge().copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 40.h),

        // Info Box
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColorsDark.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColorsDark.info.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColorsDark.info,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Didn\'t receive the email? Check your spam folder.',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 32.h),

        // Resend Button
        TextButton.icon(
          onPressed: _handleResetPassword,
          icon: const Icon(Icons.refresh),
          label: const Text('Resend Email'),
        ),

        SizedBox(height: 16.h),

        // Back to Login Button
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }
}