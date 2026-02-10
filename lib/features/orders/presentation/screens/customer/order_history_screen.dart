// lib/features/orders/presentation/screens/customer/order_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/order_card.dart';
import 'order_details_screen.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! Authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order History')),
        body: Center(child: Text('Please login to view order history')),
      );
    }

    final ordersStream = ref.watch(
      userOrderHistoryStreamProvider(authState.user.id),
    );

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Order History',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColorsDark.info.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColorsDark.info,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Showing orders from the last 5 days',
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColorsDark.info,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: ordersStream.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(Duration(milliseconds: 500));
                  },
                  color: AppColorsDark.primary,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderCard(
                        order: order,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      OrderDetailsScreen(orderId: order.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading:
                  () => Center(
                    child: CircularProgressIndicator(
                      color: AppColorsDark.primary,
                    ),
                  ),
              error:
                  (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64.sp,
                          color: AppColorsDark.error,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Error loading order history',
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.error,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: AppColorsDark.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 80.sp,
              color: AppColorsDark.textTertiary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Order History',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You haven\'t placed any orders in the last 5 days',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Start Shopping'),
          ),
        ],
      ),
    );
  }
}
