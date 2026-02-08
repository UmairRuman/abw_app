// lib/features/admin/presentation/screens/main/admin_main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../riders/rider_approval_screen.dart';
import '../restaurants/store_management_screen.dart';
import '../products/product_management_screen.dart';
import '../users/users_list_screen.dart';
import '../categories/category_management_dialog.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    RestaurantManagementScreen(),
    ProductManagementScreen(),
    UsersListScreen(),
  ];

  final List<String> _screenTitles = const [
    'Dashboard',
    'Stores',
    'Products',
    'Users',
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'AbW Services',
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
                    icon: Icons.store,
                    title: 'Stores',
                    index: 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.inventory,
                    title: 'Products',
                    index: 2,
                  ),
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: 'Users',
                    index: 3,
                  ),

                  const Divider(),

                  // Additional Actions
                  ListTile(
                    leading: const Icon(
                      Icons.category,
                      color: AppColorsDark.accent,
                    ),
                    title: Text(
                      'Manage Categories',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showCategoryManagement();
                    },
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.delivery_dining,
                      color: AppColorsDark.success,
                    ),
                    title: Text(
                      'Rider Approvals',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: const BoxDecoration(
                        color: AppColorsDark.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '0',
                        style: AppTextStyles.labelSmall().copyWith(
                          color: AppColorsDark.white,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Show rider approvals
                    },
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
                    onTap: () async {
                      // TODO: Implement logout
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
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
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColorsDark.error,
                                  ),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                      );

                      if (shouldLogout == true && mounted) {
                        // TODO: Call logout from auth provider
                        context.go('/login');
                      }
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
          color: isSelected ? AppColorsDark.primary : AppColorsDark.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColorsDark.primaryContainer.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
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
                icon: Icons.store_outlined,
                activeIcon: Icons.store,
                label: 'Stores',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.inventory_outlined,
                activeIcon: Icons.inventory,
                label: 'Products',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Users',
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
  }) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColorsDark.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color:
                  isSelected
                      ? AppColorsDark.primary
                      : AppColorsDark.textSecondary,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.labelSmall().copyWith(
                color:
                    isSelected
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

  void _showCategoryManagement() {
    showDialog(
      context: context,
      builder: (context) => const CategoryManagementDialog(),
    );
  }
}
