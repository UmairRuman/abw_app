// lib/features/orders/presentation/widgets/order_status_timeline.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../core/theme/text_styles/app_text_styles.dart';
import '../../domain/entities/order_entity.dart';
import 'package:intl/intl.dart';

class OrderStatusTimeline extends StatelessWidget {
  final OrderStatus currentStatus;
  final List<OrderStatusUpdate> statusHistory;

  const OrderStatusTimeline({
    required this.currentStatus,
    required this.statusHistory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Define all possible statuses in order
    final allStatuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];

    // Check if order was cancelled
    final isCancelled = currentStatus == OrderStatus.cancelled;

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
            'Order Status',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.h),

          if (isCancelled)
            _buildCancelledStatus()
          else
            ...allStatuses.map((status) {
              final index = allStatuses.indexOf(status);
              final isCompleted = _isStatusCompleted(status, currentStatus);
              final isCurrent = status == currentStatus;
              final isLast = index == allStatuses.length - 1;

              return _buildTimelineItem(
                status: status,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isLast: isLast,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCancelledStatus() {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: AppColorsDark.error.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColorsDark.error, width: 2),
          ),
          child: Icon(Icons.cancel, color: AppColorsDark.error, size: 24.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Cancelled',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _getStatusTime(OrderStatus.cancelled),
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required OrderStatus status,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final statusInfo = _getStatusInfo(status);
    // ✅ Get time safely
    final timeText = _getStatusTime(status);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Icon Column
            Column(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color:
                        isCompleted || isCurrent
                            ? statusInfo.color.withOpacity(0.15)
                            : AppColorsDark.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isCompleted || isCurrent
                              ? statusInfo.color
                              : AppColorsDark.border,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : statusInfo.icon,
                    color:
                        isCompleted || isCurrent
                            ? statusInfo.color
                            : AppColorsDark.textTertiary,
                    size: 24.sp,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40.h,
                    color:
                        isCompleted
                            ? statusInfo.color.withOpacity(0.3)
                            : AppColorsDark.border,
                  ),
              ],
            ),

            SizedBox(width: 16.w),

            // Status Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusInfo.title,
                      style: AppTextStyles.titleSmall().copyWith(
                        color:
                            isCompleted || isCurrent
                                ? AppColorsDark.textPrimary
                                : AppColorsDark.textSecondary,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      statusInfo.description,
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                    // ✅ Only show time if we have it
                    if ((isCompleted || isCurrent) && timeText.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        timeText,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: statusInfo.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 0),
      ],
    );
  }

  bool _isStatusCompleted(OrderStatus status, OrderStatus currentStatus) {
    final allStatuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];

    final statusIndex = allStatuses.indexOf(status);
    final currentIndex = allStatuses.indexOf(currentStatus);

    return statusIndex < currentIndex;
  }

  String _getStatusTime(OrderStatus status) {
    try {
      // ✅ Search through history for matching status
      for (final update in statusHistory) {
        if (update.status == status) {
          return DateFormat('MMM d, h:mm a').format(update.timestamp);
        }
      }
      // ✅ Not found — return empty string (status not reached yet)
      return '';
    } catch (e) {
      return '';
    }
  }

  _StatusInfo _getStatusInfo(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _StatusInfo(
          title: 'Order Placed',
          description: 'Your order has been received',
          icon: Icons.receipt_long,
          color: AppColorsDark.warning,
        );
      case OrderStatus.confirmed:
        return _StatusInfo(
          title: 'Order Confirmed',
          description: 'Restaurant confirmed your order',
          icon: Icons.check_circle,
          color: AppColorsDark.info,
        );
      case OrderStatus.preparing:
        return _StatusInfo(
          title: 'Preparing Food',
          description: 'Your food is being prepared',
          icon: Icons.restaurant,
          color: const Color(0xFFFF6B00),
        );
      case OrderStatus.outForDelivery:
        return _StatusInfo(
          title: 'Out for Delivery',
          description: 'Rider is on the way',
          icon: Icons.delivery_dining,
          color: AppColorsDark.primary,
        );
      case OrderStatus.delivered:
        return _StatusInfo(
          title: 'Delivered',
          description: 'Order delivered successfully',
          icon: Icons.task_alt,
          color: AppColorsDark.success,
        );
      case OrderStatus.cancelled:
        return _StatusInfo(
          title: 'Cancelled',
          description: 'Order was cancelled',
          icon: Icons.cancel,
          color: AppColorsDark.error,
        );
    }
  }
}

class _StatusInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _StatusInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
