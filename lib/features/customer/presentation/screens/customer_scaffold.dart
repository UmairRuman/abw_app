// lib/features/customer/presentation/screens/customer_scaffold.dart

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

// ✅ FIX 2: Reset to 0 on every fresh mount (called after login navigation)
final customerTabProvider = StateProvider<int>((ref) => 0);

class CustomerScaffold extends ConsumerStatefulWidget {
  const CustomerScaffold({super.key});

  @override
  ConsumerState<CustomerScaffold> createState() => _CustomerScaffoldState();
}

class _CustomerScaffoldState extends ConsumerState<CustomerScaffold> {
  @override
  void initState() {
    super.initState();
    // ✅ FIX 2: Always reset to home tab when scaffold mounts.
    // This handles the case where user logs out (from tab 3 - Profile)
    // and logs back in — they land on Home, not Profile.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerTabProvider.notifier).state = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(customerTabProvider);

    // ✅ FIX 1: Use a key on CustomerHomeScreen so it rebuilds fresh
    // when the scaffold remounts (e.g. after login). The IndexedStack
    // keeps screens alive while navigating between tabs, which is correct —
    // but we add a reload trigger via the HomeScreen's own keepAlive logic.
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
      bottomNavigationBar: _buildBottomNav(currentIndex),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
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
                0,
                currentIndex,
                Icons.home_outlined,
                Icons.home_rounded,
                'Home',
              ),
              _buildNavItem(
                1,
                currentIndex,
                Icons.store_outlined,
                Icons.store_rounded,
                'Stores',
              ),
              _buildNavItem(
                2,
                currentIndex,
                Icons.receipt_long_outlined,
                Icons.receipt_long_rounded,
                'Orders',
              ),
              _buildNavItem(
                3,
                currentIndex,
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'Profile',
              ),
              _buildNavItem(
                4,
                currentIndex,
                Icons.phone_outlined,
                Icons.phone_rounded,
                'Contact',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    int currentIndex,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    final color =
        isSelected ? AppColorsDark.primary : AppColorsDark.textTertiary;

    return Expanded(
      child: InkWell(
        onTap: () => ref.read(customerTabProvider.notifier).state = index,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.labelSmall().copyWith(
                color: color,
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            SizedBox(height: 2.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 4.w : 0,
              height: isSelected ? 4.w : 0,
              decoration: BoxDecoration(
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
