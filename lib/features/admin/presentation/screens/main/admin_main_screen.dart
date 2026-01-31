// lib/features/admin/presentation/screens/main/admin_main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../riders/rider_approval_screen.dart';
import '../restaurants/restaurant_management_screen.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    RiderApprovalScreen(),
    RestaurantManagementScreen(),
    AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      drawer: _buildDrawer(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColorsDark.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: const BoxDecoration(
                gradient: AppColorsDark.primaryGradient,
              ),
              child: Column(
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: const BoxDecoration(
                      color: AppColorsDark.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40.sp,
                      color: AppColorsDark.primary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Admin Panel',
                    style: AppTextStyles.titleLarge().copyWith(
                      color: AppColorsDark.white,
                    ),
                  ),
                  Text(
                    'admin@abw.com',
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColorsDark.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.delivery_dining,
                    title: 'Rider Approvals',
                    index: 1,
                    badge: '3',
                  ),
                  _buildDrawerItem(
                    icon: Icons.restaurant,
                    title: 'Restaurants',
                    index: 2,
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    index: 3,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColorsDark.error,
                    ),
                    title: Text(
                      'Logout',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.error,
                      ),
                    ),
                    onTap: () {
                      // TODO: Implement logout
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    String? badge,
  }) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColorsDark.primary : AppColorsDark.textSecondary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium().copyWith(
          color: isSelected
              ? AppColorsDark.primary
              : AppColorsDark.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
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
            )
          : null,
      selected: isSelected,
      selectedTileColor: AppColorsDark.primaryContainer.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColorsDark.surface,
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.shadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.delivery_dining_outlined,
                activeIcon: Icons.delivery_dining,
                label: 'Riders',
                index: 1,
                badge: '3',
              ),
              _buildNavItem(
                icon: Icons.restaurant_outlined,
                activeIcon: Icons.restaurant,
                label: 'Restaurants',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    String? badge,
  }) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorsDark.primaryContainer.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected
                      ? AppColorsDark.primary
                      : AppColorsDark.textSecondary,
                  size: 24.sp,
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: AppColorsDark.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge,
                        style: AppTextStyles.labelSmall().copyWith(
                          color: AppColorsDark.white,
                          fontSize: 8.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.labelSmall().copyWith(
                color: isSelected
                    ? AppColorsDark.primary
                    : AppColorsDark.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder Settings Screen
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Admin Settings',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 80.sp,
              color: AppColorsDark.textTertiary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Settings Feature',
              style: AppTextStyles.headlineSmall().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Configuration options coming soon',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}