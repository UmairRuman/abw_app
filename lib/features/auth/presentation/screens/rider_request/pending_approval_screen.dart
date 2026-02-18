// lib/features/auth/presentation/screens/rider_request/pending_approval_screen.dart
// REPLACE ENTIRE FILE WITH THIS:

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  StreamSubscription<DocumentSnapshot>? _approvalListener;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    //  START REAL-TIME LISTENER (NO AUTO-REDIRECT)
    _listenForApproval();
  }

  //  REAL-TIME LISTENER - ONLY REDIRECTS WHEN APPROVED
  void _listenForApproval() {
    final authState = ref.read(authProvider);

    if (authState is! RiderPendingApproval && authState is! Authenticated) {
      return;
    }

    final String userId =
        authState is RiderPendingApproval
            ? authState.user.id
            : (authState as Authenticated).user.id;

    log('👂 Listening for approval: $userId');

    // ✅ LISTEN TO riders COLLECTION (not users!)
    _approvalListener = FirebaseFirestore.instance
        .collection('riders') // ✅ CHANGED FROM users TO riders
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;

            // ✅ HANDLE DOCUMENT NOT YET EXISTING
            if (!snapshot.exists) {
              log('⏳ Rider document not in riders collection yet...');
              return;
            }

            final data = snapshot.data();
            if (data == null) return;

            final isApproved = data['isApproved'] as bool? ?? false;
            log('📡 Approval status: $isApproved');

            if (isApproved) {
              log('✅ Approved! Redirecting...');
              _approvalListener?.cancel();

              ref.read(authProvider.notifier).refreshUser().then((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Account approved!'),
                      backgroundColor: AppColorsDark.success,
                    ),
                  );
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) context.go('/rider/dashboard');
                  });
                }
              });
            }
          },
          onError: (error) {
            log('⚠️ Listener error: $error');
          },
          cancelOnError: false,
        );
  }

  // ✅ MANUAL CHECK STATUS BUTTON
  Future<void> _checkApprovalStatus() async {
    setState(() => _isCheckingStatus = true);

    try {
      final authState = ref.read(authProvider);

      String userId;
      if (authState is RiderPendingApproval) {
        userId = authState.user.id;
      } else if (authState is Authenticated) {
        userId = authState.user.id;
      } else {
        // Not authenticated - this shouldn't happen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: AppColorsDark.error,
            ),
          );
          context.go('/login');
        }
        return;
      }

      log('🔍 Manually checking approval for: $userId');

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userDoc.exists) {
        // User document doesn't exist yet (still in rider_requests only)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏳ Still pending admin review'),
              backgroundColor: AppColorsDark.warning,
            ),
          );
        }
        setState(() => _isCheckingStatus = false);
        return;
      }

      final userData = userDoc.data()!;
      final isApproved = userData['isApproved'] as bool? ?? false;

      if (isApproved) {
        // ✅ APPROVED!
        log('✅ Approved! Refreshing and redirecting...');

        await ref.read(authProvider.notifier).refreshUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Approved! Redirecting...'),
              backgroundColor: AppColorsDark.success,
            ),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go('/rider/dashboard');
            }
          });
        }
      } else {
        // ❌ STILL PENDING
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Still under review. Please check back later.'),
              backgroundColor: AppColorsDark.info,
            ),
          );
        }
      }
    } catch (e) {
      log('❌ Error checking status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  @override
  void dispose() {
    _approvalListener?.cancel(); // ✅ CANCEL LISTENER ON DISPOSE
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40.h),

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
                          color: AppColorsDark.warning.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.pending_actions,
                          size: 60.sp,
                          color: AppColorsDark.warning,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 32.h),

                // Title
                Text(
                  'Account Pending Approval',
                  style: AppTextStyles.headlineMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16.h),

                // Description
                Text(
                  'Your rider registration is currently under review by our admin team. You\'ll be notified once your account is approved.',
                  style: AppTextStyles.bodyLarge().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40.h),

                // Status Card
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColorsDark.cardBackground,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColorsDark.border, width: 1),
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
                          'Approval usually takes 24-48 hours. We\'ll notify you automatically when approved!',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Check Status Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingStatus ? null : _checkApprovalStatus,
                    icon:
                        _isCheckingStatus
                            ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColorsDark.white,
                              ),
                            )
                            : Icon(Icons.refresh, size: 20.sp),
                    label: Text(
                      _isCheckingStatus ? 'Checking...' : 'Check Status',
                      style: AppTextStyles.button(),
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // Logout Button
                TextButton(
                  onPressed: () async {
                    _approvalListener?.cancel();
                    await ref.read(authProvider.notifier).logout();
                    if (mounted) {
                      context.go('/login');
                    }
                  },
                  child: Text(
                    'Logout',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.error,
                    ),
                  ),
                ),
              ],
            ),
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
      color = AppColorsDark.success;
    } else if (isActive) {
      color = AppColorsDark.warning;
    } else {
      color = AppColorsDark.textTertiary;
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
          child: Icon(icon, color: color, size: 20.sp),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
