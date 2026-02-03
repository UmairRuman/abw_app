// lib/features/admin/presentation/screens/users/widgets/user_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../../shared/enums/user_role.dart';
import '../../../../../auth/data/models/customer_model.dart';
import '../../../../../auth/data/models/rider_model.dart';

class UserDetailsDialog extends StatelessWidget {
  final dynamic user;
  final UserRole role;

  const UserDetailsDialog({
    super.key,
    required this.user,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColorsDark.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: 600.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: role == UserRole.customer
                    ? _buildCustomerDetails(user as CustomerModel)
                    : _buildRiderDetails(user as RiderModel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = role == UserRole.customer
        ? (user as CustomerModel).name
        : (user as RiderModel).name;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: role == UserRole.customer
            ? AppColorsDark.primaryGradient
            : const LinearGradient(
                colors: [
                  AppColorsDark.success,
                  AppColorsDark.successLight,
                ],
              ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: AppColorsDark.white,
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Center(
              child: role == UserRole.customer
                  ? Text(
                      name.substring(0, 2).toUpperCase(),
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(
                      Icons.delivery_dining,
                      color: AppColorsDark.success,
                      size: 30.sp,
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  role == UserRole.customer ? 'Customer' : 'Rider',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.close,
                color: AppColorsDark.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails(CustomerModel customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: 'Contact Information',
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: customer.email,
              ),
              if (customer.phone != null)
                _buildInfoRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: customer.phone!,
                ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        _buildSection(
          title: 'Account Details',
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Joined',
                value: DateFormat('MMM dd, yyyy').format(customer.createdAt),
              ),
              _buildInfoRow(
                icon: Icons.update,
                label: 'Last Updated',
                value: DateFormat('MMM dd, yyyy').format(customer.updatedAt),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        _buildSection(
          title: 'Statistics',
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.shopping_bag,
                  label: 'Total Orders',
                  value: '0',
                  color: AppColorsDark.info,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  label: 'Total Spent',
                  value: 'PKR 0',
                  color: AppColorsDark.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiderDetails(RiderModel rider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status
        _buildSection(
          title: 'Status',
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: rider.isApproved
                  ? AppColorsDark.success.withOpacity(0.2)
                  : AppColorsDark.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: rider.isApproved
                    ? AppColorsDark.success
                    : AppColorsDark.warning,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  rider.isApproved ? Icons.check_circle : Icons.pending,
                  color: rider.isApproved
                      ? AppColorsDark.success
                      : AppColorsDark.warning,
                ),
                SizedBox(width: 8.w),
                Text(
                  rider.isApproved
                      ? 'Approved & Active'
                      : 'Pending Approval',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: rider.isApproved
                        ? AppColorsDark.success
                        : AppColorsDark.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),

        _buildSection(
          title: 'Contact Information',
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: rider.email,
              ),
              if (rider.phone != null)
                _buildInfoRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: rider.phone!,
                ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        if (rider.vehicleType != null || rider.vehicleNumber != null)
          _buildSection(
            title: 'Vehicle Information',
            child: Column(
              children: [
                if (rider.vehicleType != null)
                  _buildInfoRow(
                    icon: Icons.two_wheeler,
                    label: 'Vehicle Type',
                    value: rider.vehicleType!,
                  ),
                if (rider.vehicleNumber != null)
                  _buildInfoRow(
                    icon: Icons.confirmation_number,
                    label: 'Vehicle Number',
                    value: rider.vehicleNumber!,
                  ),
              ],
            ),
          ),
        SizedBox(height: 20.h),

        _buildSection(
          title: 'Account Details',
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Joined',
                value: DateFormat('MMM dd, yyyy').format(rider.createdAt),
              ),
              if (rider.approvedAt != null)
                _buildInfoRow(
                  icon: Icons.check,
                  label: 'Approved On',
                  value: DateFormat('MMM dd, yyyy').format(rider.approvedAt!),
                ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        _buildSection(
          title: 'Statistics',
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_shipping,
                  label: 'Deliveries',
                  value: '0',
                  color: AppColorsDark.success,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  label: 'Earnings',
                  value: 'PKR 0',
                  color: AppColorsDark.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall().copyWith(
            color: AppColorsDark.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        child,
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: AppColorsDark.textSecondary,
          ),
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
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
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
        children: [
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTextStyles.labelSmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}