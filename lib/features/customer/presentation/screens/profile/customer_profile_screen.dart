// lib/features/customer/presentation/screens/profile/customer_profile_screen.dart

import 'package:abw_app/features/auth/data/models/customer_model.dart';
import 'package:abw_app/features/auth/domain/entities/user_entity.dart';
import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:abw_app/features/customer/presentation/screens/profile/customer_edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../../orders/presentation/screens/customer/active_orders_screen.dart';
import '../../../../orders/presentation/screens/customer/order_history_screen.dart';

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
    await Future.delayed(
      const Duration(milliseconds: 200),
    ); // Ensure context is available
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      await ref
          .read(addressesProvider.notifier)
          .loadUserAddresses(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final addressesState = ref.watch(addressesProvider);

    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: Text('Please login')));
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
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: AppColorsDark.white,
            size: 20.sp,
          ),
        ),
        onPressed: () {
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
            context.push('/customer/edit-profile');
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
                  user.name.isNotEmpty
                      ? user.name.substring(0, 2).toUpperCase()
                      : 'U',
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

            ...[
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

  Widget _buildMenuSection(
    BuildContext context,
    AddressesState addressesState,
  ) {
    int addressCount = 0;
    if (addressesState is AddressesLoaded) {
      addressCount = addressesState.addresses.length;
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        SizedBox(height: 8.h),

        // Account section
        _buildSection(context, 'Account', [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerEditProfileScreen(),
                ),
              );
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

        // Orders section
        _buildSection(context, 'Orders', [
          _buildMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Active Orders',
            subtitle: 'Track your ongoing orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActiveOrdersScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Order History',
            subtitle: 'View orders from last 5 days',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
        ]),

        SizedBox(height: 16.h),

        // ✅ NEW: Delete Account Button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: OutlinedButton(
            onPressed: () => _showDeleteAccountDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorsDark.error,
              side: const BorderSide(color: AppColorsDark.error),
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_forever, size: 20.sp),
                SizedBox(width: 8.w),
                const Text('Delete Account'),
              ],
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // Logout button (keep this)
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

  // ✅ NEW: Delete Account Dialog
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            icon: Icon(
              Icons.warning_amber_rounded,
              color: AppColorsDark.error,
              size: 48.sp,
            ),
            title: Text(
              'Delete Account?',
              style: AppTextStyles.titleLarge().copyWith(
                color: AppColorsDark.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action will permanently delete your account.',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColorsDark.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColorsDark.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What will happen:',
                        style: AppTextStyles.labelMedium().copyWith(
                          color: AppColorsDark.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      _buildConsequenceItem(
                        'You will be logged out immediately',
                      ),
                      _buildConsequenceItem('You cannot place new orders'),
                      _buildConsequenceItem('You cannot login again'),
                      SizedBox(height: 8.h),
                      Text(
                        'Your order history will be kept for business records.',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.info,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColorsDark.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleDeleteAccount(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                ),
                child: const Text('Delete My Account'),
              ),
            ],
          ),
    );
  }

  // ✅ Helper widget for consequence list
  Widget _buildConsequenceItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.close, size: 16.sp, color: AppColorsDark.error),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Handle Account Deletion
  Future<void> _handleDeleteAccount(BuildContext context) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColorsDark.surface,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColorsDark.primary,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Deleting account...',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

      // ✅ Soft delete: Mark account as deleted
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authState.user.id)
          .update({
            'isDeleted': true,
            'deletedAt': FieldValue.serverTimestamp(),
            'deletedReason': 'User requested deletion',
          });

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Logout
      await ref.read(authProvider.notifier).logout();

      // Show success message and navigate to login
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12.w),
                const Expanded(
                  child: Text('Your account has been deleted successfully'),
                ),
              ],
            ),
            backgroundColor: AppColorsDark.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate to login
        context.go('/login');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColorsDark.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
    required VoidCallback onTap,
    String? subtitle,
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
      subtitle:
          subtitle != null
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
