// lib/features/rider/presentation/screens/earnings/rider_earnings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
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
          'My Earnings',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body: riderStream.when(
        data: (rider) {
          if (rider == null)
            return const Center(child: Text('Rider not found'));

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Total Earnings Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: AppColorsDark.primaryGradient,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsDark.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: AppColorsDark.white.withOpacity(0.8),
                        size: 40.sp,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Total Earnings',
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'PKR ${rider.totalEarnings.toInt()}',
                        style: AppTextStyles.displaySmall().copyWith(
                          color: AppColorsDark.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Deliveries',
                        value: rider.totalDeliveries.toString(),
                        icon: Icons.delivery_dining,
                        color: AppColorsDark.success,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Avg per Delivery',
                        value:
                            rider.totalDeliveries > 0
                                ? 'PKR ${(rider.totalEarnings / rider.totalDeliveries).toInt()}'
                                : 'PKR 0',
                        icon: Icons.trending_up,
                        color: AppColorsDark.info,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Delivered Orders History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery History',
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Last 5 days',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                deliveredOrdersStream.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.h),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 64.sp,
                              color: AppColorsDark.textTertiary,
                            ),
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

                    return Column(
                      children:
                          orders
                              .map((order) => _buildEarningItem(order))
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
              color: color.withOpacity(0.15),
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

  Widget _buildEarningItem(OrderEntity order) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(16.w),
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
                Text(
                  DateFormat('MMM d, h:mm a').format(order.updatedAt),
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+PKR ${order.deliveryFee.toInt()}',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
