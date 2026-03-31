// lib/features/admin/presentation/widgets/admin_drawer.dart

import 'package:abw_app/features/admin/presentation/screens/categories/category_management_dialog.dart';
import 'package:abw_app/features/admin/presentation/screens/settings/payment_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    String adminName = 'Admin';
    String adminEmail = 'admin@abw.com';

    if (authState is Authenticated) {
      adminName = authState.user.name;
      adminEmail = authState.user.email;
    }

    return Drawer(
      backgroundColor: AppColorsDark.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildDrawerHeader(adminName, adminEmail),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                children: [
                  _buildSectionHeader('OVERVIEW'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/admin/dashboard');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.analytics_rounded,
                    title: 'Analytics',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/analytics');
                    },
                  ),

                  _buildDivider(),
                  _buildSectionHeader('MANAGEMENT'),

                  _buildDrawerItem(
                    context,
                    icon: Icons.receipt_long_rounded,
                    title: 'Orders',
                    badge: _buildOrdersBadge(ref),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/orders');
                    },
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.inventory_rounded,
                    title: 'Products',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/products');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.category_rounded,
                    title: 'Categories',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => const CategoryManagementDialog(),
                      );
                      // Show dialog or navigate to categories screen
                    },
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.delivery_dining_rounded,
                    title: 'Riders',
                    badge: _buildRidersBadge(ref),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/riders-list'); // ← already wired
                    },
                  ),

                  _buildDivider(),
                  _buildSectionHeader('USERS'),

                  _buildDrawerItem(
                    context,
                    icon: Icons.people_rounded,
                    title: 'All Users',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/users');
                    },
                  ),

                  _buildDivider(),
                  _buildSectionHeader('SETTINGS'),

                  _buildDrawerItem(
                    context,
                    icon: Icons.image_outlined,
                    title: 'Banners',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/banners');
                    },
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.payment_rounded,
                    title: 'Payment Settings',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => const PaymentSettingsDialog(),
                      );
                      // Show payment settings dialog
                    },
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.support_agent_rounded,
                    title: 'Contact Us Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/contact-settings');
                    },
                  ),
                ],
              ),
            ),

            // Footer
            _buildDrawerFooter(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(String name, String email) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: const BoxDecoration(gradient: AppColorsDark.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: AppColorsDark.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColorsDark.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: AppTextStyles.displaySmall().copyWith(
                  color: AppColorsDark.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Name
          Text(
            name,
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),

          // Email
          Text(
            email,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 12.h),

          // Admin Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColorsDark.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColorsDark.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: AppColorsDark.white,
                  size: 14.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Administrator',
                  style: AppTextStyles.labelSmall().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
      child: Text(
        title,
        style: AppTextStyles.labelSmall().copyWith(
          color: AppColorsDark.textTertiary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColorsDark.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: AppColorsDark.primary, size: 20.sp),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium().copyWith(
          color: AppColorsDark.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          badge ??
          Icon(
            Icons.chevron_right,
            color: AppColorsDark.textTertiary,
            size: 20.sp,
          ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: const Divider(color: AppColorsDark.border, height: 1),
    );
  }

  Widget _buildOrdersBadge(WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }
        final count = snapshot.data!.docs.length;
        return _buildBadge(count.toString());
      },
    );
  }

  Widget _buildStoresBadge(WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('stores')
              .where('isApproved', isEqualTo: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }
        final count = snapshot.data!.docs.length;
        return _buildBadge(count.toString());
      },
    );
  }

  Widget _buildRidersBadge(WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'rider')
              .where('isApproved', isEqualTo: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }
        final count = snapshot.data!.docs.length;
        return _buildBadge(count.toString());
      },
    );
  }

  Widget _buildBadge(String count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColorsDark.error,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        count,
        style: AppTextStyles.labelSmall().copyWith(
          color: AppColorsDark.white,
          fontWeight: FontWeight.bold,
          fontSize: 10.sp,
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Divider(color: AppColorsDark.border, height: 1),
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColorsDark.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: AppColorsDark.error,
              size: 20.sp,
            ),
          ),
          title: Text(
            'Logout',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => _showLogoutDialog(context, ref),
          contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Logout',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    context.go('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}
