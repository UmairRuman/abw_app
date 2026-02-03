// lib/features/admin/presentation/screens/restaurants/widgets/store_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../stores/data/models/store_model.dart';

class StoreDetailsDialog extends StatelessWidget {
  final StoreModel store;

  const StoreDetailsDialog({
    super.key,
    required this.store,
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
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: AppColorsDark.primaryGradient,
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
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.store,
                      size: 30.sp,
                      color: AppColorsDark.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: AppTextStyles.titleMedium().copyWith(
                            color: AppColorsDark.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          store.type,
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColorsDark.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Status',
                      child: _buildStatusRow(),
                    ),
                    SizedBox(height: 20.h),
                    
                    _buildSection(
                      title: 'Contact Information',
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'Owner',
                            value: store.ownerName,
                          ),
                          _buildInfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: store.ownerEmail,
                          ),
                          _buildInfoRow(
                            icon: Icons.phone,
                            label: 'Phone',
                            value: store.ownerPhone,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    
                    _buildSection(
                      title: 'Location',
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.location_on,
                            label: 'Address',
                            value: store.address,
                          ),
                          _buildInfoRow(
                            icon: Icons.location_city,
                            label: 'City',
                            value: '${store.area}, ${store.city}',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    
                    _buildSection(
                      title: 'Delivery Info',
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.delivery_dining,
                            label: 'Delivery Fee',
                            value: 'PKR ${store.deliveryFee.toStringAsFixed(0)}',
                          ),
                          _buildInfoRow(
                            icon: Icons.timer,
                            label: 'Delivery Time',
                            value: '${store.deliveryTime} mins',
                          ),
                          _buildInfoRow(
                            icon: Icons.shopping_cart,
                            label: 'Min Order',
                            value: 'PKR ${store.minimumOrder.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    
                    _buildSection(
                      title: 'Operating Hours',
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.access_time,
                            label: 'Hours',
                            value: '${store.openingTime} - ${store.closingTime}',
                          ),
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'Working Days',
                            value: store.workingDays.join(', '),
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
                              icon: Icons.star,
                              label: 'Rating',
                              value: store.rating.toStringAsFixed(1),
                              color: AppColorsDark.warning,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.shopping_bag,
                              label: 'Orders',
                              value: '${store.totalOrders}',
                              color: AppColorsDark.info,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.rate_review,
                              label: 'Reviews',
                              value: '${store.totalReviews}',
                              color: AppColorsDark.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (store.cuisines.isNotEmpty) ...[
                      SizedBox(height: 20.h),
                      _buildSection(
                        title: 'Cuisines',
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: store.cuisines
                              .map((cuisine) => Chip(
                                    label: Text(cuisine),
                                    backgroundColor:
                                        AppColorsDark.primaryContainer,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    
                    if (store.tags.isNotEmpty) ...[
                      SizedBox(height: 20.h),
                      _buildSection(
                        title: 'Tags',
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: store.tags
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    backgroundColor:
                                        AppColorsDark.secondaryContainer,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

Widget _buildStatusRow() {
  return Wrap(
    spacing: 8.w,
    runSpacing: 6.h,
    children: [
      _buildStatusChip(
        label: store.isApproved ? 'Approved' : 'Pending',
        color:
            store.isApproved ? AppColorsDark.success : AppColorsDark.warning,
        icon: store.isApproved ? Icons.check_circle : Icons.pending,
      ),
      _buildStatusChip(
        label: store.isActive ? 'Active' : 'Inactive',
        color: store.isActive ? AppColorsDark.success : AppColorsDark.error,
        icon: store.isActive ? Icons.visibility : Icons.visibility_off,
      ),
      _buildStatusChip(
        label: store.isOpen ? 'Open' : 'Closed',
        color: store.isOpen ? AppColorsDark.info : AppColorsDark.error,
        icon: store.isOpen ? Icons.lock_open : Icons.lock,
      ),
    ],
  );
}


  Widget _buildStatusChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.labelSmall().copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
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
          ),
        ],
      ),
    );
  }
}