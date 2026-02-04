// lib/features/customer/presentation/screens/profile/customer_profile_screen.dart

import 'package:abw_app/features/auth/data/models/customer_model.dart';
import 'package:abw_app/features/auth/domain/entities/user_entity.dart';
import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../addresses/presentation/providers/addresses_provider.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    await Future.delayed(const Duration(milliseconds: 200)); // Ensure context is available
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      await ref.read(addressesProvider.notifier).loadUserAddresses(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final addressesState = ref.watch(addressesProvider);

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    final user = authState.user;

    return Scaffold(
      
      backgroundColor: AppColorsDark.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildProfileHeader(context, user),
          _buildMenuSection(context, addressesState),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
       leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColorsDark.background.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: AppColorsDark.white,
            size: 20.sp,
          ),
        ),
        onPressed: () {
      //      ref.read(categoriesProvider.notifier).getAllCategories();
      // ref.read(storesProvider.notifier).getAllStores();
          context.pop();
        },
      ),
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
          icon: const Icon(Icons.edit),
          color: AppColorsDark.textPrimary,
          onPressed: () {
            // TODO: Edit profile
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserEntity user) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 100.w,
              height: 100.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColorsDark.primaryGradient,
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name.substring(0, 2).toUpperCase() : 'U',
                  style: AppTextStyles.headlineLarge().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            Text(
              user.name,
              style: AppTextStyles.headlineMedium().copyWith(
                color: AppColorsDark.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 4.h),

            Text(
              user.email,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),

            if (user.phone != null) ...[
              SizedBox(height: 4.h),
              Text(
                user.phone!,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, AddressesState addressesState) {
    int addressCount = 0;
    if (addressesState is AddressesLoaded) {
      addressCount = addressesState.addresses.length;
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        SizedBox(height: 8.h),
        _buildSection(context, 'Account', [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () {
              // TODO: Edit personal info
            },
          ),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            subtitle: '$addressCount saved addresses',
            onTap: () {
              context.push('/customer/addresses');
            },
          ),
        ]),
        _buildSection(context, 'Orders', [
          _buildMenuItem(
            icon: Icons.history,
            title: 'Order History',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order history coming in Milestone 2'),
                  backgroundColor: AppColorsDark.info,
                ),
              );
            },
          ),
        ]),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: OutlinedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorsDark.error,
              side: const BorderSide(color: AppColorsDark.error),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
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
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColorsDark.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: AppColorsDark.primary, size: 20.sp),
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
      trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
      onTap: onTap,
    );
  }
}