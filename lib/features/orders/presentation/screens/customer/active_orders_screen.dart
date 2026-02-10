// lib/features/orders/presentation/screens/customer/active_orders_screen.dart

import 'package:abw_app/features/orders/domain/entities/order_entity.dart';
import 'package:abw_app/features/orders/presentation/screens/customer/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../providers/orders_provider.dart';

import '../../widgets/order_card.dart';

class ActiveOrdersScreen extends ConsumerWidget {
  const ActiveOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! Authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Orders')),
        body: const Center(child: Text('Please login to view orders')),
      );
    }

    final ordersStream = ref.watch(userOrdersStreamProvider(authState.user.id));

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Active Orders',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body: ordersStream.when(
        data: (orders) {
          // Filter only active orders (not delivered or cancelled)
          final activeOrders =
              orders.where((order) {
                return order.status != OrderStatus.delivered &&
                    order.status != OrderStatus.cancelled;
              }).toList();

          if (activeOrders.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh is handled automatically by StreamProvider
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColorsDark.primary,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                return OrderCard(
                  order: order,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => OrderDetailsScreen(orderId: order.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColorsDark.primary),
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
                    'Error loading orders',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.error,
                    ),
                  ),
                ],
              ),
            ),
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
            decoration: const BoxDecoration(
              color: AppColorsDark.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 80.sp,
              color: AppColorsDark.textTertiary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Active Orders',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You don\'t have any active orders right now',
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
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }
}
