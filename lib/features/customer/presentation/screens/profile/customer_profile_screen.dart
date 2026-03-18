// lib/features/customer/presentation/screens/profile/customer_profile_screen.dart

import 'package:abw_app/features/auth/data/models/customer_model.dart';
import 'package:abw_app/features/auth/domain/entities/user_entity.dart';
import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:abw_app/features/customer/presentation/screens/profile/customer_edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          (ctx) => AlertDialog(
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
                  'This will permanently delete your account from the app.',
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
                        'What happens:',
                        style: AppTextStyles.labelMedium().copyWith(
                          color: AppColorsDark.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      _buildConsequenceItem('Your login will be removed'),
                      _buildConsequenceItem('You cannot sign in again'),
                      _buildConsequenceItem(
                        'Your order history is kept for records',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColorsDark.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _handleDeleteAccount();
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
  Future<void> _handleDeleteAccount() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    final userId = authState.user.id;
    bool dialogOpen = false;

    // Helper: closes loading dialog safely
    void closeDialog() {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
    }

    // Show loading dialog
    if (mounted) {
      dialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => PopScope(
              canPop: false,
              child: Center(
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
            ),
      );
    }

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        closeDialog();
        return;
      }

      // ── Step 1: Wipe personal data in Firestore ───────────────────────
      // The document stays so admin can still see order history,
      // but all personal info is removed (GDPR / Play Store compliant).
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'name': 'Deleted User',
        'email': 'deleted_${userId.substring(0, 6)}@deleted.com',
        'phone': '',
        'profileImage': null,
        'fcmToken': null,
        'address': null,
        'latitude': null,
        'longitude': null,
        'isActive': false,
      });

      // ── Step 2: Delete Firebase Auth account ─────────────────────────
      // Required by Google Play Store & Apple App Store policies.
      await firebaseUser.delete();

      // ── Step 3: Sign out silently ─────────────────────────────────────
      // Auth account is already gone — just clear the local session.
      await FirebaseAuth.instance.signOut();

      closeDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted.'),
            backgroundColor: AppColorsDark.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/login');
      }
    } on FirebaseAuthException catch (e) {
      closeDialog();
      if (e.code == 'requires-recent-login') {
        // Firebase requires a fresh login before deleting the account.
        // Show password confirmation dialog and retry.
        if (mounted) _showReAuthDialog();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message ?? e.code}'),
              backgroundColor: AppColorsDark.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      closeDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColorsDark.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Firebase throws requires-recent-login when the session is old.
  /// Re-authenticates with password then retries _handleDeleteAccount.
  void _showReAuthDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder:
              (ctx, setDialogState) => AlertDialog(
                backgroundColor: AppColorsDark.surface,
                title: Text(
                  'Confirm your password',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'For security, please enter your password to confirm deletion.',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: AppColorsDark.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColorsDark.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              if (passwordController.text.trim().isEmpty)
                                return;
                              setDialogState(() => isLoading = true);

                              try {
                                final firebaseUser =
                                    FirebaseAuth.instance.currentUser;
                                if (firebaseUser?.email == null) {
                                  Navigator.pop(ctx);
                                  return;
                                }

                                // Re-authenticate with fresh credentials
                                final credential = EmailAuthProvider.credential(
                                  email: firebaseUser!.email!,
                                  password: passwordController.text.trim(),
                                );
                                await firebaseUser.reauthenticateWithCredential(
                                  credential,
                                );

                                Navigator.pop(ctx);
                                // Session is now fresh — retry deletion
                                _handleDeleteAccount();
                              } on FirebaseAuthException catch (e) {
                                setDialogState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.code == 'wrong-password'
                                          ? 'Incorrect password. Please try again.'
                                          : 'Error: ${e.message ?? e.code}',
                                    ),
                                    backgroundColor: AppColorsDark.error,
                                  ),
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsDark.error,
                    ),
                    child:
                        isLoading
                            ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColorsDark.white,
                              ),
                            )
                            : const Text('Confirm'),
                  ),
                ],
              ),
        );
      },
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
