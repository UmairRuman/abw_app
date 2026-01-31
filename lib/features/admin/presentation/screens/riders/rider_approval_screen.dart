// lib/features/admin/presentation/screens/riders/rider_approval_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class RiderApprovalScreen extends ConsumerStatefulWidget {
  const RiderApprovalScreen({super.key});

  @override
  ConsumerState<RiderApprovalScreen> createState() =>
      _RiderApprovalScreenState();
}

class _RiderApprovalScreenState extends ConsumerState<RiderApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Rider Approvals',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColorsDark.primary,
          labelColor: AppColorsDark.primary,
          unselectedLabelColor: AppColorsDark.textSecondary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(),
          _buildApprovedList(),
          _buildRejectedList(),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 5, // TODO: Replace with actual data
      itemBuilder: (context, index) => _buildRiderCard(
        name: 'Rider ${index + 1}',
        email: 'rider${index + 1}@example.com',
        phone: '+92 300 1234567',
        vehicle: 'Bike',
        vehicleNumber: 'ABC-${1234 + index}',
        requestDate: '2 days ago',
        status: 'pending',
        onApprove: () => _showApprovalDialog(context, 'Rider ${index + 1}', true),
        onReject: () => _showApprovalDialog(context, 'Rider ${index + 1}', false),
      ),
    );
  }

  Widget _buildApprovedList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 12, // TODO: Replace with actual data
      itemBuilder: (context, index) => _buildRiderCard(
        name: 'Approved Rider ${index + 1}',
        email: 'approved${index + 1}@example.com',
        phone: '+92 300 1234567',
        vehicle: index % 2 == 0 ? 'Bike' : 'Scooter',
        vehicleNumber: 'XYZ-${5000 + index}',
        requestDate: '${index + 1} days ago',
        status: 'approved',
      ),
    );
  }

  Widget _buildRejectedList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 3, // TODO: Replace with actual data
      itemBuilder: (context, index) => _buildRiderCard(
        name: 'Rejected Rider ${index + 1}',
        email: 'rejected${index + 1}@example.com',
        phone: '+92 300 1234567',
        vehicle: 'Car',
        vehicleNumber: 'LMN-${8000 + index}',
        requestDate: '${index + 3} days ago',
        status: 'rejected',
        rejectionReason: 'Incomplete documents',
      ),
    );
  }

  Widget _buildRiderCard({
    required String name,
    required String email,
    required String phone,
    required String vehicle,
    required String vehicleNumber,
    required String requestDate,
    required String status,
    String? rejectionReason,
    VoidCallback? onApprove,
    VoidCallback? onReject,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    gradient: AppColorsDark.primaryGradient,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 2).toUpperCase(),
                      style: AppTextStyles.titleLarge().copyWith(
                        color: AppColorsDark.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTextStyles.titleMedium().copyWith(
                                color: AppColorsDark.textPrimary,
                              ),
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      _buildInfoRow(Icons.email_outlined, email),
                      SizedBox(height: 4.h),
                      _buildInfoRow(Icons.phone_outlined, phone),
                      SizedBox(height: 4.h),
                      _buildInfoRow(
                        Icons.delivery_dining,
                        '$vehicle - $vehicleNumber',
                      ),
                      SizedBox(height: 4.h),
                      _buildInfoRow(
                        Icons.access_time,
                        'Requested $requestDate',
                      ),
                      if (rejectionReason != null) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColorsDark.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColorsDark.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16.sp,
                                color: AppColorsDark.error,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Reason: $rejectionReason',
                                  style: AppTextStyles.bodySmall().copyWith(
                                    color: AppColorsDark.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons (for pending only)
          if (status == 'pending') ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsDark.success,
                        foregroundColor: AppColorsDark.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColorsDark.error,
                        side: BorderSide(color: AppColorsDark.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: AppColorsDark.textTertiary,
        ),
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = AppColorsDark.warning;
        label = 'PENDING';
        break;
      case 'approved':
        color = AppColorsDark.success;
        label = 'APPROVED';
        break;
      case 'rejected':
        color = AppColorsDark.error;
        label = 'REJECTED';
        break;
      default:
        color = AppColorsDark.textTertiary;
        label = status.toUpperCase();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall().copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showApprovalDialog(BuildContext context, String riderName, bool isApprove) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          isApprove ? 'Approve Rider' : 'Reject Rider',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? 'Are you sure you want to approve $riderName?'
                  : 'Are you sure you want to reject $riderName?',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            if (!isApprove) ...[
              SizedBox(height: 16.h),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'Enter reason for rejection',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement approval/rejection logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isApprove
                        ? '$riderName has been approved!'
                        : '$riderName has been rejected!',
                  ),
                  backgroundColor: isApprove
                      ? AppColorsDark.success
                      : AppColorsDark.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove
                  ? AppColorsDark.success
                  : AppColorsDark.error,
            ),
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
} 