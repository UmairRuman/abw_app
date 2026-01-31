// lib/features/customer/presentation/screens/profile/customer_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildProfileHeader(context),
          _buildMenuSection(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColorsDark.surface,
      title: Text(
        'Profile',
        style: AppTextStyles.titleLarge().copyWith(
          color: AppColorsDark.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          color: AppColorsDark.textPrimary,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColorsDark.primaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      'JD',
                      style: AppTextStyles.headlineLarge().copyWith(
                        color: AppColorsDark.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColorsDark.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColorsDark.background,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16.sp,
                      color: AppColorsDark.background,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Name
            Text(
              'John Doe',
              style: AppTextStyles.headlineMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),

            SizedBox(height: 4.h),

            // Email
            Text(
              'john.doe@example.com',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),

            SizedBox(height: 20.h),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  icon: Icons.shopping_bag,
                  label: 'Orders',
                  value: '24',
                ),
                _buildStatCard(
                  icon: Icons.favorite,
                  label: 'Favorites',
                  value: '12',
                ),
                _buildStatCard(
                  icon: Icons.credit_card,
                  label: 'Wallet',
                  value: '\$250',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColorsDark.primary,
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.titleMedium().copyWith(
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

  Widget _buildMenuSection(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        SizedBox(height: 8.h),
        _buildSection(context, 'Account', [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            subtitle: '3 saved addresses',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.credit_card,
            title: 'Payment Methods',
            onTap: () {},
          ),
        ]),
        _buildSection(context, 'Orders', [
          _buildMenuItem(
            icon: Icons.history,
            title: 'Order History',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.favorite_outline,
            title: 'Favorite Orders',
            onTap: () {},
          ),
        ]),
        _buildSection(context, 'Preferences', [
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            trailing: Switch(
              value: true,
              onChanged: (val) {},
              activeColor: AppColorsDark.primary,
            ),
          ),
          _buildMenuItem(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: true,
              onChanged: (val) {},
              activeColor: AppColorsDark.primary,
            ),
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),
        ]),
        _buildSection(context, 'Support', [
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
        ]),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorsDark.error,
              side: BorderSide(color: AppColorsDark.error),
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, size: 20.sp),
                SizedBox(width: 8.w),
                const Text('Logout'),
              ],
            ),
          ),
        ),
        SizedBox(height: 32.h),
      ]),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Text(
            title,
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColorsDark.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColorsDark.border),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColorsDark.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: AppColorsDark.primary,
          size: 20.sp,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium().copyWith(
          color: AppColorsDark.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16.sp,
            color: AppColorsDark.textTertiary,
          ),
      onTap: onTap,
    );
  }
}