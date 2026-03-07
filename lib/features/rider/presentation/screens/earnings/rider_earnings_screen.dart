// lib/features/rider/presentation/screens/earnings/rider_earnings_screen.dart
// UPDATED:
//   ✅ Removed salary/earnings display (hidden from rider)
//   ✅ Shows: total deliveries, total distance, total collected cash
//   ✅ Shows today's stats separately (admin can clear these)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../auth/data/models/rider_model.dart';
import '../../../../riders/presentation/providers/riders_provider.dart';
import '../../../../orders/presentation/providers/orders_provider.dart';
import '../../../../orders/domain/entities/order_entity.dart';

class RiderEarningsScreen extends ConsumerWidget {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) return const SizedBox();

    final riderId = authState.user.id;
    final riderStream = ref.watch(riderStreamProvider(riderId));
    final deliveredOrdersStream = ref.watch(
      riderDeliveredOrdersProvider(riderId),
    );

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'My Performance',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body: riderStream.when(
        data: (rider) {
          if (rider == null) {
            return const Center(child: Text('Rider not found'));
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── All-time Stats ─────────────────────────────────────────
                Text(
                  'All-Time Stats',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Deliveries',
                        value: rider.totalDeliveries.toString(),
                        icon: Icons.delivery_dining,
                        color: AppColorsDark.primary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Distance',
                        value: _formatDistance(rider.totalDistance),
                        icon: Icons.route,
                        color: AppColorsDark.info,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                // Full-width cash card
                _buildCashCard(rider),

                SizedBox(height: 24.h),

                // ── Today's Stats ──────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      "Today's Stats",
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorsDark.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColorsDark.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        DateFormat('MMM d').format(DateTime.now()),
                        style: AppTextStyles.labelSmall().copyWith(
                          color: AppColorsDark.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Deliveries Today',
                        value: rider.todayDeliveries.toString(),
                        icon: Icons.today,
                        color: AppColorsDark.success,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Cash Collected Today',
                        value: 'PKR ${rider.todayCollectedCash.toInt()}',
                        icon: Icons.payments_outlined,
                        color: AppColorsDark.warning,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // ── Delivery History ───────────────────────────────────────
                Text(
                  'Recent Deliveries',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),

                deliveredOrdersStream.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return _buildEmptyHistory();
                    }
                    return Column(
                      children:
                          orders
                              .map((order) => _buildDeliveryItem(order))
                              .toList(),
                    );
                  },
                  loading:
                      () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColorsDark.primary,
                        ),
                      ),
                  error: (e, _) => const Text('Error loading history'),
                ),
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

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: AppTextStyles.headlineSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCard(RiderModel rider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsDark.success,
            AppColorsDark.success.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.success.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColorsDark.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.payments,
              color: AppColorsDark.white,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Cash Collected',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.white.withOpacity(0.85),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'PKR ${rider.totalCollectedCash.toInt()}',
                style: AppTextStyles.headlineSmall().copyWith(
                  color: AppColorsDark.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Cash received from customers (COD orders)',
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryItem(OrderEntity order) {
    final isCOD = order.paymentMethod == PaymentMethod.cod;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColorsDark.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.task_alt,
              color: AppColorsDark.success,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 6)}',
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  order.storeName,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      DateFormat('MMM d, h:mm a').format(order.updatedAt),
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textTertiary,
                      ),
                    ),
                    if (order.distance != null) ...[
                      Text(
                        ' · ',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textTertiary,
                        ),
                      ),
                      Text(
                        _formatDistance(order.distance!),
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.info,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isCOD)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColorsDark.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'COD',
                    style: AppTextStyles.labelSmall().copyWith(
                      color: AppColorsDark.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              SizedBox(height: 4.h),
              Text(
                isCOD ? 'Collected PKR ${order.total.toInt()}' : 'Online paid',
                style: AppTextStyles.labelSmall().copyWith(
                  color:
                      isCOD
                          ? AppColorsDark.success
                          : AppColorsDark.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          Icon(Icons.history, size: 56.sp, color: AppColorsDark.textTertiary),
          SizedBox(height: 16.h),
          Text(
            'No deliveries yet',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }
}
