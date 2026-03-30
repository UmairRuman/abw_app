// lib/features/customer/presentation/screens/customer_scaffold.dart
// Main scaffold with bottom navigation bar for the customer section.

import 'package:abw_app/features/customer/presentation/screens/home/all_stores_screen.dart';
import 'package:abw_app/features/orders/presentation/screens/customer/active_orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../core/theme/text_styles/app_text_styles.dart';
import 'home/customer_home_screen.dart';

import 'profile/customer_profile_screen.dart';
import 'contact/customer_contact_screen.dart';

// Provider to control which tab is active from anywhere in the app
final customerTabProvider = StateProvider<int>((ref) => 0);

class CustomerScaffold extends ConsumerWidget {
  const CustomerScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(customerTabProvider);

    final screens = [
      const CustomerHomeScreen(),
      const AllStoresScreen(initialCategoryId: '', initialCategoryName: 'All'),
      const ActiveOrdersScreen(),
      const CustomerProfileScreen(),
      const CustomerContactScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: _buildBottomNav(context, ref, currentIndex),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColorsDark.surface,
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.shadow,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64.h,
          child: Row(
            children: [
              _buildNavItem(
                ref: ref,
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                ref: ref,
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.store_outlined,
                activeIcon: Icons.store_rounded,
                label: 'Stores',
              ),
              _buildNavItem(
                ref: ref,
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Orders',
                showBadge: true,
              ),
              _buildNavItem(
                ref: ref,
                index: 3,
                currentIndex: currentIndex,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
              _buildNavItem(
                ref: ref,
                index: 4,
                currentIndex: currentIndex,
                icon: Icons.support_agent_outlined,
                activeIcon: Icons.support_agent_rounded,
                label: 'Contact',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required WidgetRef ref,
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool showBadge = false,
  }) {
    final isSelected = currentIndex == index;
    final color =
        isSelected ? AppColorsDark.primary : AppColorsDark.textTertiary;

    return Expanded(
      child: InkWell(
        onTap: () => ref.read(customerTabProvider.notifier).state = index,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    color: color,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.labelSmall().copyWith(
                color: color,
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // Active indicator dot
            SizedBox(height: 2.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 4.w : 0,
              height: isSelected ? 4.w : 0,
              decoration: const BoxDecoration(
                color: AppColorsDark.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
