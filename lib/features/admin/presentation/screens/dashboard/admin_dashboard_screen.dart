// lib/features/admin/presentation/screens/dashboard/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildStatsGrid(),
            _buildQuickActions(context),
            _buildPendingApprovals(context),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColorsDark.surface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Dashboard',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          Text(
            'Welcome back, Admin',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppColorsDark.textPrimary,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.5,
        ),
        delegate: SliverChildListDelegate([
          _buildStatCard(
            title: 'Total Orders',
            value: '1,247',
            icon: Icons.shopping_bag,
            color: AppColorsDark.primary,
            trend: '+12%',
            isPositive: true,
          ),
          _buildStatCard(
            title: 'Active Riders',
            value: '42',
            icon: Icons.delivery_dining,
            color: AppColorsDark.success,
            trend: '+5',
            isPositive: true,
          ),
          _buildStatCard(
            title: 'Restaurants',
            value: '156',
            icon: Icons.restaurant,
            color: AppColorsDark.accent,
            trend: '+8',
            isPositive: true,
          ),
          _buildStatCard(
            title: 'Revenue',
            value: '\$12.5k',
            icon: Icons.attach_money,
            color: AppColorsDark.warning,
            trend: '+18%',
            isPositive: true,
          ),
        ]),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsDark.cardBackground,
            AppColorsDark.surfaceVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24.sp,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColorsDark.success.withOpacity(0.2)
                      : AppColorsDark.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12.sp,
                      color: isPositive
                          ? AppColorsDark.success
                          : AppColorsDark.error,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      trend,
                      style: AppTextStyles.labelSmall().copyWith(
                        color: isPositive
                            ? AppColorsDark.success
                            : AppColorsDark.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.person_add,
                    label: 'Approve Riders',
                    color: AppColorsDark.primary,
                    badge: '3',
                    onTap: () {
                      // TODO: Navigate to rider approvals
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.restaurant,
                    label: 'Add Restaurant',
                    color: AppColorsDark.accent,
                    onTap: () {
                      // TODO: Navigate to add restaurant
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsDark.border),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28.sp,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppColorsDark.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge,
                        style: AppTextStyles.labelSmall().copyWith(
                          color: AppColorsDark.white,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovals(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Approvals',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all approvals
                  },
                  child: Text(
                    'View All',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildApprovalCard(
              name: 'John Rider',
              vehicle: 'Bike - ABC-1234',
              time: '2 hours ago',
            ),
            SizedBox(height: 8.h),
            _buildApprovalCard(
              name: 'Mike Delivery',
              vehicle: 'Scooter - XYZ-5678',
              time: '5 hours ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard({
    required String name,
    required String vehicle,
    required String time,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              gradient: AppColorsDark.primaryGradient,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                name.substring(0, 2).toUpperCase(),
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  vehicle,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  time,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.check_circle,
                  color: AppColorsDark.success,
                  size: 24.sp,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  Icons.cancel,
                  color: AppColorsDark.error,
                  size: 24.sp,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            _buildActivityItem(
              icon: Icons.check_circle,
              title: 'Rider Approved',
              subtitle: 'John Doe was approved as a rider',
              time: '10 min ago',
              color: AppColorsDark.success,
            ),
            _buildActivityItem(
              icon: Icons.restaurant,
              title: 'New Restaurant',
              subtitle: 'Pizza Palace added to platform',
              time: '1 hour ago',
              color: AppColorsDark.accent,
            ),
            _buildActivityItem(
              icon: Icons.shopping_bag,
              title: 'Order Completed',
              subtitle: 'Order #1234 delivered successfully',
              time: '2 hours ago',
              color: AppColorsDark.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}