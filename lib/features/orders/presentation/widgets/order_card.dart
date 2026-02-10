// lib/features/orders/presentation/widgets/order_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../core/theme/text_styles/app_text_styles.dart';
import '../../data/models/order_model.dart';
import '../../domain/entities/order_entity.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColorsDark.border),
          boxShadow: const [
            BoxShadow(
              color: AppColorsDark.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Order ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(order.id.length - 6)}',
                        style: AppTextStyles.titleSmall().copyWith(
                          color: AppColorsDark.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formatDate(order.createdAt),
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                _buildStatusBadge(order.status),
              ],
            ),

            SizedBox(height: 12.h),
            const Divider(color: AppColorsDark.border),
            SizedBox(height: 12.h),

            // Store Name
            Row(
              children: [
                Icon(
                  Icons.store,
                  size: 16.sp,
                  color: AppColorsDark.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    order.storeName,
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Items Count
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 16.sp,
                  color: AppColorsDark.textSecondary,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Total Amount
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 18.sp,
                      color: AppColorsDark.primary,
                    ),
                    Text(
                      'PKR ${order.total.toInt()}',
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // View Details Button
                Row(
                  children: [
                    Text(
                      'View Details',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12.sp,
                      color: AppColorsDark.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = AppColorsDark.warning.withOpacity(0.15);
        textColor = AppColorsDark.warning;
        text = 'Pending';
        icon = Icons.pending;
        break;
      case OrderStatus.confirmed:
        backgroundColor = AppColorsDark.info.withOpacity(0.15);
        textColor = AppColorsDark.info;
        text = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case OrderStatus.preparing:
        backgroundColor = const Color(0xFFFF6B00).withOpacity(0.15);
        textColor = const Color(0xFFFF6B00);
        text = 'Preparing';
        icon = Icons.restaurant;
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = AppColorsDark.primary.withOpacity(0.15);
        textColor = AppColorsDark.primary;
        text = 'On the Way';
        icon = Icons.delivery_dining;
        break;
      case OrderStatus.delivered:
        backgroundColor = AppColorsDark.success.withOpacity(0.15);
        textColor = AppColorsDark.success;
        text = 'Delivered';
        icon = Icons.task_alt;
        break;
      case OrderStatus.cancelled:
        backgroundColor = AppColorsDark.error.withOpacity(0.15);
        textColor = AppColorsDark.error;
        text = 'Cancelled';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: textColor),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppTextStyles.labelSmall().copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final orderDate = DateTime(date.year, date.month, date.day);

    if (orderDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (orderDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }
}
