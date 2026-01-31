// lib/features/auth/presentation/screens/rider_request/pending_approval_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Clock Icon
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pending_actions,
                        size: 60.sp,
                        color: AppColors.warning,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                'Account Pending Approval',
                style: AppTextStyles.headlineMedium(),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16.h),

              // Description
              Text(
                'Your rider registration is currently under review by our admin team. You\'ll be notified once your account is approved.',
                style: AppTextStyles.bodyLarge().copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 40.h),

              // Status Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildStatusItem(
                      icon: Icons.check_circle,
                      title: 'Application Submitted',
                      subtitle: 'Your details have been received',
                      isCompleted: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildStatusItem(
                      icon: Icons.pending,
                      title: 'Under Review',
                      subtitle: 'Admin is reviewing your application',
                      isCompleted: false,
                      isActive: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildStatusItem(
                      icon: Icons.verified,
                      title: 'Approval',
                      subtitle: 'You\'ll be notified once approved',
                      isCompleted: false,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              // Info Box
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Approval usually takes 24-48 hours. Check back soon!',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Refresh status from provider
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Status'),
                ),
              ),

              SizedBox(height: 12.h),

              TextButton(
                onPressed: () {
                  // TODO: Logout and go back to login
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: Text(
                  'Logout',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isActive = false,
  }) {
    Color color;
    if (isCompleted) {
      color = AppColors.success;
    } else if (isActive) {
      color = AppColors.warning;
    } else {
      color = AppColors.grey400;
    }

    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall().copyWith(
                  color: color,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}