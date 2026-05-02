// lib/features/rider/presentation/screens/profile/rider_profile_screen.dart

import 'package:abw_app/features/auth/data/models/rider_model.dart';
import 'package:abw_app/features/auth/domain/entities/rider_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../riders/presentation/providers/riders_provider.dart';

// ✅ Convert to ConsumerStatefulWidget — needed for _handleDeleteAccount
class RiderProfileScreen extends ConsumerStatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  ConsumerState<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends ConsumerState<RiderProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) return const SizedBox();

    final riderStream = ref.watch(riderStreamProvider(authState.user.id));

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body: riderStream.when(
        data: (rider) {
          if (rider == null) {
            return const Center(child: Text('Profile not found'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: AppColorsDark.primaryGradient,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: AppColorsDark.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            rider.name.substring(0, 1).toUpperCase(),
                            style: AppTextStyles.displaySmall().copyWith(
                              color: AppColorsDark.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        rider.name,
                        style: AppTextStyles.headlineMedium().copyWith(
                          color: AppColorsDark.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        rider.phone,
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Account Info
                _buildInfoCard(rider),

                SizedBox(height: 20.h),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: Icon(Icons.logout, size: 20.sp),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColorsDark.error,
                      side: const BorderSide(color: AppColorsDark.error),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // ✅ Delete Account Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteAccountDialog(context),
                    icon: Icon(Icons.delete_forever, size: 20.sp),
                    label: const Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsDark.error,
                      foregroundColor: AppColorsDark.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),
              ],
            ),
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColorsDark.primary),
            ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ✅ Delete Account Dialog
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
                  'This will permanently delete your rider account.',
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
                        'Your delivery history is kept for records',
                      ),
                      _buildConsequenceItem(
                        'Any active orders will be unassigned',
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

  // ✅ Handle Account Deletion
  Future<void> _handleDeleteAccount() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    final userId = authState.user.id;
    bool dialogOpen = false;

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
            (_) => const AlertDialog(
              backgroundColor: AppColorsDark.surface,
              content: Row(
                children: [
                  CircularProgressIndicator(color: AppColorsDark.primary),
                  SizedBox(width: 16),
                  Text('Deleting account...'),
                ],
              ),
            ),
      );
    }

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Step 1 — Remove from users collection
      batch.delete(FirebaseFirestore.instance.collection('users').doc(userId));

      // Step 2 — Remove from riders collection
      batch.delete(FirebaseFirestore.instance.collection('riders').doc(userId));

      // Step 3 — Unassign any active orders assigned to this rider
      final activeOrders =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('riderId', isEqualTo: userId)
              .where('status', whereIn: ['confirmed', 'picked_up'])
              .get();

      for (final doc in activeOrders.docs) {
        batch.update(doc.reference, {
          'riderId': null,
          'riderName': null,
          'riderPhone': null,
          'status': 'pending', // Put back to pending so admin can reassign
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Step 4 — Delete Firebase Auth account
      await FirebaseAuth.instance.currentUser?.delete();

      closeDialog();

      if (mounted) context.go('/login');
    } catch (e) {
      closeDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  Widget _buildInfoCard(RiderModel rider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(Icons.person, 'Name', rider.name),
          Divider(color: AppColorsDark.border, height: 24.h),
          _buildInfoRow(Icons.email, 'Email', rider.email),
          Divider(color: AppColorsDark.border, height: 24.h),
          _buildInfoRow(Icons.phone, 'Phone', rider.phone),
          Divider(color: AppColorsDark.border, height: 24.h),
          _buildInfoRow(
            Icons.verified,
            'Account',
            rider.isApproved ? 'Approved ✅' : 'Pending Approval',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColorsDark.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
