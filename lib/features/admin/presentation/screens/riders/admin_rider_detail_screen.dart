// lib/features/admin/presentation/screens/riders/admin_rider_detail_screen.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/data/models/rider_model.dart';
import '../../../../riders/data/collections/riders_collection.dart';

class AdminRiderDetailScreen extends ConsumerStatefulWidget {
  final String riderId;

  const AdminRiderDetailScreen({required this.riderId, super.key});

  @override
  ConsumerState<AdminRiderDetailScreen> createState() =>
      _AdminRiderDetailScreenState();
}

class _AdminRiderDetailScreenState
    extends ConsumerState<AdminRiderDetailScreen> {
  final RidersCollection _ridersCollection = RidersCollection();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Rider Details',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body: StreamBuilder<RiderModel?>(
        stream: _ridersCollection.getRiderStream(widget.riderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColorsDark.primary),
            );
          }

          final rider = snapshot.data;
          if (rider == null) {
            return Center(
              child: Text(
                'Rider not found',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.error,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(rider),
                SizedBox(height: 16.h),
                _buildAnalyticsCard(rider),
                SizedBox(height: 16.h),
                _buildTodayCard(rider),
                SizedBox(height: 16.h),
                _buildClearActionsCard(rider),
                SizedBox(height: 16.h),
                _buildStatusCard(rider),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Profile ──────────────────────────────────────────────────────────────

  Widget _buildProfileCard(RiderModel rider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32.r,
            backgroundColor: AppColorsDark.primary.withOpacity(0.2),
            child: Icon(
              Icons.delivery_dining,
              color: AppColorsDark.primary,
              size: 32.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.name,
                  style: AppTextStyles.titleLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  rider.email,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  rider.phone,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _buildBadge(
                      rider.isApproved ? 'Approved' : 'Pending',
                      rider.isApproved
                          ? AppColorsDark.success
                          : AppColorsDark.warning,
                    ),
                    SizedBox(width: 8.w),
                    _buildBadge(
                      rider.status.name.toUpperCase(),
                      rider.status.name == 'available'
                          ? AppColorsDark.success
                          : rider.status.name == 'busy'
                          ? AppColorsDark.warning
                          : AppColorsDark.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── All-Time Analytics ───────────────────────────────────────────────────

  Widget _buildAnalyticsCard(RiderModel rider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            Icons.bar_chart,
            'All-Time Analytics',
            AppColorsDark.primary,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  icon: Icons.delivery_dining,
                  label: 'Deliveries',
                  value: '${rider.totalDeliveries}',
                  color: AppColorsDark.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatBox(
                  icon: Icons.monetization_on,
                  label: 'Earnings',
                  value: 'PKR ${rider.totalEarnings.toInt()}',
                  color: AppColorsDark.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  icon: Icons.account_balance_wallet,
                  label: 'Cash Collected',
                  value: 'PKR ${rider.totalCollectedCash.toInt()}',
                  color: AppColorsDark.warning,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatBox(
                  icon: Icons.route,
                  label: 'Distance',
                  value:
                      rider.totalDistance >= 1000
                          ? '${(rider.totalDistance / 1000).toStringAsFixed(1)} km'
                          : '${rider.totalDistance.toInt()} m',
                  color: AppColorsDark.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Today's Stats ────────────────────────────────────────────────────────

  Widget _buildTodayCard(RiderModel rider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.today, "Today's Stats", AppColorsDark.info),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  icon: Icons.delivery_dining,
                  label: "Today's Deliveries",
                  value: '${rider.todayDeliveries}',
                  color: AppColorsDark.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatBox(
                  icon: Icons.money,
                  label: 'Cash Today',
                  value: 'PKR ${rider.todayCollectedCash.toInt()}',
                  color: AppColorsDark.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Clear Actions ────────────────────────────────────────────────────────

  Widget _buildClearActionsCard(RiderModel rider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            Icons.cleaning_services,
            'Clear Records',
            AppColorsDark.error,
          ),
          SizedBox(height: 8.h),
          Text(
            'These actions are irreversible. Confirm before proceeding.',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),

          // Clear Today's Records
          _buildClearButton(
            label: "Clear Today's Records",
            subtitle: "Resets today's deliveries and collected cash to 0",
            icon: Icons.today,
            color: AppColorsDark.warning,
            onTap:
                () => _showConfirmDialog(
                  title: "Clear Today's Records",
                  body:
                      "This will reset today's deliveries (${rider.todayDeliveries}) and today's cash (PKR ${rider.todayCollectedCash.toInt()}) to zero.",
                  onConfirm: () => _clearTodayRecords(rider.id),
                ),
          ),

          SizedBox(height: 10.h),

          // Clear Collected Cash
          _buildClearButton(
            label: 'Clear Collected Cash',
            subtitle:
                'Resets all-time + today cash to 0 (marks as handed over)',
            icon: Icons.account_balance_wallet,
            color: AppColorsDark.info,
            onTap:
                () => _showConfirmDialog(
                  title: 'Clear Collected Cash',
                  body:
                      'This will reset total collected cash (PKR ${rider.totalCollectedCash.toInt()}) and today\'s cash to zero. Use this after the rider hands over cash.',
                  onConfirm: () => _clearCollectedCash(rider.id),
                ),
          ),

          SizedBox(height: 10.h),

          // Clear All Analytics
          _buildClearButton(
            label: 'Clear All Analytics',
            subtitle: 'Resets ALL stats — deliveries, earnings, distance, cash',
            icon: Icons.delete_sweep,
            color: AppColorsDark.error,
            onTap:
                () => _showConfirmDialog(
                  title: 'Clear ALL Analytics',
                  body:
                      'This will permanently reset ALL analytics for ${rider.name}:\n\n'
                      '• Total deliveries: ${rider.totalDeliveries}\n'
                      '• Total earnings: PKR ${rider.totalEarnings.toInt()}\n'
                      '• Cash collected: PKR ${rider.totalCollectedCash.toInt()}\n'
                      '• Distance: ${rider.totalDistance.toStringAsFixed(1)} m\n\n'
                      'This cannot be undone.',
                  onConfirm: () => _clearAllAnalytics(rider.id),
                  isDangerous: true,
                ),
          ),
        ],
      ),
    );
  }

  // ── Status / Force Logout ────────────────────────────────────────────────

  Widget _buildStatusCard(RiderModel rider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            Icons.manage_accounts,
            'Account Actions',
            AppColorsDark.primary,
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _isProcessing
                      ? null
                      : () => _showConfirmDialog(
                        title: 'Force Logout Rider',
                        body:
                            'This will clear the active device lock for ${rider.name}. They will need to log in again.',
                        onConfirm: () => _forceLogout(rider.id),
                      ),
              icon: Icon(Icons.logout, size: 20.sp),
              label: const Text('Force Logout (Clear Device Lock)'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: const BorderSide(color: AppColorsDark.error),
                foregroundColor: AppColorsDark.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: AppTextStyles.titleMedium().copyWith(
            color: AppColorsDark.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.titleMedium().copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClearButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.titleSmall().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall().copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColorsDark.cardBackground,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: AppColorsDark.border),
    );
  }

  // ── Confirm Dialog ────────────────────────────────────────────────────────

  void _showConfirmDialog({
    required String title,
    required String body,
    required Future<void> Function() onConfirm,
    bool isDangerous = false,
  }) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            icon: Icon(
              isDangerous ? Icons.warning_amber_rounded : Icons.help_outline,
              color: isDangerous ? AppColorsDark.error : AppColorsDark.warning,
              size: 48.sp,
            ),
            title: Text(
              title,
              style: AppTextStyles.titleLarge().copyWith(
                color: AppColorsDark.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              body,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColorsDark.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDangerous ? AppColorsDark.error : AppColorsDark.warning,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _clearTodayRecords(String riderId) async {
    setState(() => _isProcessing = true);
    try {
      final success = await _ridersCollection.clearTodayRecords(riderId);
      _showResult(success, "Today's records cleared");
    } catch (e) {
      _showResult(false, e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _clearCollectedCash(String riderId) async {
    setState(() => _isProcessing = true);
    try {
      final success = await _ridersCollection.clearCollectedCash(riderId);
      _showResult(success, 'Collected cash cleared');
    } catch (e) {
      _showResult(false, e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _clearAllAnalytics(String riderId) async {
    setState(() => _isProcessing = true);
    try {
      final success = await _ridersCollection.clearAllAnalytics(riderId);
      _showResult(success, 'All analytics cleared');
    } catch (e) {
      _showResult(false, e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _forceLogout(String riderId) async {
    setState(() => _isProcessing = true);
    try {
      final success = await _ridersCollection.adminForceLogoutRider(riderId);
      _showResult(success, 'Device lock cleared — rider must log in again');
    } catch (e) {
      _showResult(false, e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResult(bool success, String successMessage) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(success ? successMessage : 'Operation failed'),
            ),
          ],
        ),
        backgroundColor: success ? AppColorsDark.success : AppColorsDark.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
