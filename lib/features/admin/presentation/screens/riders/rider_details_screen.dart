// lib/features/admin/presentation/screens/riders/rider_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/data/models/rider_model.dart';
import '../../../../auth/domain/entities/rider_entity.dart';

class RiderDetailsScreen extends ConsumerStatefulWidget {
  final String riderId;

  const RiderDetailsScreen({super.key, required this.riderId});

  @override
  ConsumerState<RiderDetailsScreen> createState() => _RiderDetailsScreenState();
}

class _RiderDetailsScreenState extends ConsumerState<RiderDetailsScreen> {
  bool _isUpdating = false;

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
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(widget.riderId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColorsDark.primary),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Rider not found'));
          }

          final rider = RiderModel.fromJson({
            'id': snapshot.data!.id,
            ...snapshot.data!.data() as Map<String, dynamic>,
          });

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(rider),
                SizedBox(height: 20.h),

                // Approval Section (if pending)
                if (!rider.isApproved) _buildApprovalSection(rider),
                if (!rider.isApproved) SizedBox(height: 20.h),

                // Stats
                _buildStatsRow(rider),
                SizedBox(height: 20.h),

                // Personal Info
                _buildInfoSection(rider),
                SizedBox(height: 20.h),

                // Vehicle Info
                _buildVehicleInfo(rider),
                SizedBox(height: 20.h),

                // Recent Deliveries
                _buildRecentDeliveries(rider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(RiderModel rider) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: AppColorsDark.primaryGradient,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          // Avatar
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

          // Name
          Text(
            rider.name,
            style: AppTextStyles.headlineMedium().copyWith(
              color: AppColorsDark.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),

          // Phone
          Text(
            rider.phone,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 12.h),

          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _getStatusColor(rider).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: _getStatusColor(rider).withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: _getStatusColor(rider),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _getStatusText(rider),
                  style: AppTextStyles.labelMedium().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalSection(RiderModel rider) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pending_actions,
                color: AppColorsDark.warning,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Pending Approval',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : () => _approveRider(rider),
                  icon: Icon(Icons.check, size: 18.sp),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsDark.success,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUpdating ? null : () => _rejectRider(rider),
                  icon: Icon(Icons.close, size: 18.sp),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColorsDark.error,
                    side: BorderSide(color: AppColorsDark.error),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(RiderModel rider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Total Deliveries',
            value: rider.totalDeliveries.toString(),
            icon: Icons.delivery_dining,
            color: AppColorsDark.primary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            label: 'Total Earnings',
            value: 'PKR ${rider.totalEarnings.toInt()}',
            icon: Icons.monetization_on,
            color: AppColorsDark.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.titleLarge().copyWith(
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

  Widget _buildInfoSection(RiderModel rider) {
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
            'Personal Information',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(Icons.email, 'Email', rider.email),
          Divider(color: AppColorsDark.border, height: 24.h),
          _buildInfoRow(Icons.phone, 'Phone', rider.phone),
          Divider(color: AppColorsDark.border, height: 24.h),
          _buildInfoRow(
            Icons.calendar_today,
            'Joined',
            DateFormat('MMM d, yyyy').format(rider.createdAt),
          ),
          if (rider.approvedAt != null) ...[
            Divider(color: AppColorsDark.border, height: 24.h),
            _buildInfoRow(
              Icons.verified,
              'Approved On',
              DateFormat('MMM d, yyyy').format(rider.approvedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleInfo(RiderModel rider) {
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
            'Vehicle Information',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(Icons.two_wheeler, 'Vehicle Type', rider.vehicleType),
          Divider(color: AppColorsDark.border, height: 24.h),
          _buildInfoRow(Icons.numbers, 'Vehicle Number', rider.vehicleNumber),
          if (rider.licenseNumber != null) ...[
            Divider(color: AppColorsDark.border, height: 24.h),
            _buildInfoRow(Icons.badge, 'License Number', rider.licenseNumber!),
          ],
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

  Widget _buildRecentDeliveries(RiderModel rider) {
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
            'Recent Deliveries',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('orders')
                    .where('riderId', isEqualTo: rider.id)
                    .where('status', isEqualTo: 'delivered')
                    .orderBy('updatedAt', descending: true)
                    .limit(5)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  'No deliveries yet',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                );
              }

              return Column(
                children:
                    snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16.sp,
                              color: AppColorsDark.success,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Order #${doc.id.substring(doc.id.length - 6)}',
                                style: AppTextStyles.bodySmall().copyWith(
                                  color: AppColorsDark.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '+PKR ${(data['deliveryFee'] as num).toInt()}',
                              style: AppTextStyles.bodySmall().copyWith(
                                color: AppColorsDark.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RiderModel rider) {
    if (!rider.isApproved) return AppColorsDark.warning;
    switch (rider.status) {
      case RiderStatus.available:
        return AppColorsDark.success;
      case RiderStatus.busy:
        return AppColorsDark.primary;
      case RiderStatus.offline:
        return AppColorsDark.textTertiary;
    }
  }

  String _getStatusText(RiderModel rider) {
    if (!rider.isApproved) return 'PENDING APPROVAL';
    switch (rider.status) {
      case RiderStatus.available:
        return 'ONLINE';
      case RiderStatus.busy:
        return 'BUSY';
      case RiderStatus.offline:
        return 'OFFLINE';
    }
  }

  Future<void> _approveRider(RiderModel rider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Approve Rider?',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Text(
              'Approve ${rider.name} to start accepting deliveries?',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.success,
                ),
                child: const Text('Approve'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isUpdating = true);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(rider.id)
            .update({
              'isApproved': true,
              'approvedAt': FieldValue.serverTimestamp(),
              'approvedBy': 'admin', // You can pass actual admin ID here
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${rider.name} approved successfully!'),
              backgroundColor: AppColorsDark.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColorsDark.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _rejectRider(RiderModel rider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Reject Rider?',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Text(
              'This will permanently delete ${rider.name}\'s account.',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isUpdating = true);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(rider.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rider rejected and removed'),
              backgroundColor: AppColorsDark.error,
            ),
          );
          Navigator.pop(context); // Go back to list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColorsDark.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }
}
