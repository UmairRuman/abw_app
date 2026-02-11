// lib/features/rider/presentation/screens/profile/rider_profile_screen.dart

import 'package:abw_app/features/auth/data/models/rider_model.dart';
import 'package:abw_app/features/auth/domain/entities/rider_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../riders/presentation/providers/riders_provider.dart';

class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) return const SizedBox();

    final riderStream = ref.watch(riderStreamProvider(authState.user.id));

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body: riderStream.when(
        data: (rider) {
          if (rider == null) {
            return const Center(child: Text('Profile not found'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: AppColorsDark.primaryGradient,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: AppColorsDark.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            rider.name.substring(0, 1).toUpperCase(),
                            style: AppTextStyles.displaySmall().copyWith(
                              color: AppColorsDark.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        rider.name,
                        style: AppTextStyles.headlineMedium().copyWith(
                          color: AppColorsDark.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        rider.phone,
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(rider.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: _getStatusColor(
                              rider.status,
                            ).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: _getStatusColor(rider.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              rider.status.name.toUpperCase(),
                              style: AppTextStyles.labelMedium().copyWith(
                                color: AppColorsDark.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        label: 'Total Deliveries',
                        value: rider.totalDeliveries.toString(),
                        icon: Icons.delivery_dining,
                        color: AppColorsDark.primary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildStatTile(
                        label: 'Total Earnings',
                        value: 'PKR ${rider.totalEarnings.toInt()}',
                        icon: Icons.monetization_on,
                        color: AppColorsDark.success,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Account Info
                _buildInfoCard(rider),

                SizedBox(height: 20.h),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: Icon(Icons.logout, size: 20.sp),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColorsDark.error,
                      side: const BorderSide(color: AppColorsDark.error),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),
              ],
            ),
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColorsDark.primary),
            ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(RiderModel rider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(Icons.person, 'Name', rider.name),
          Divider(color: AppColorsDark.border, height: 24.h),
          _buildInfoRow(Icons.email, 'Email', rider.email),
          Divider(color: AppColorsDark.border, height: 24.h),
          _buildInfoRow(Icons.phone, 'Phone', rider.phone),
          Divider(color: AppColorsDark.border, height: 24.h),
          _buildInfoRow(
            Icons.verified,
            'Account',
            rider.isApproved ? 'Approved ✅' : 'Pending Approval',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColorsDark.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(RiderStatus status) {
    switch (status) {
      case RiderStatus.available:
        return AppColorsDark.success;
      case RiderStatus.busy:
        return AppColorsDark.warning;
      case RiderStatus.offline:
        return AppColorsDark.textTertiary;
    }
  }
}
