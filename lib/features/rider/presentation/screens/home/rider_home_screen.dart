// lib/features/rider/presentation/screens/home/rider_home_screen.dart

import 'package:abw_app/features/auth/data/models/rider_model.dart';
import 'package:abw_app/features/auth/domain/entities/rider_entity.dart';
import 'package:abw_app/features/rider/presentation/screens/home/rider_active_delivery_screen.dart';
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
import '../../../../orders/data/models/order_model.dart';
import '../../../../orders/domain/entities/order_entity.dart';

class RiderHomeScreen extends ConsumerWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    final riderId = authState.user.id;
    final riderStream = ref.watch(riderStreamProvider(riderId));

    return riderStream.when(
      data: (rider) {
        if (rider == null) {
          return const Scaffold(body: Center(child: Text('Rider not found')));
        }
        return _RiderHomeContent(rider: rider);
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _RiderHomeContent extends ConsumerWidget {
  final RiderModel rider;

  const _RiderHomeContent({required this.rider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch assigned orders for this rider
    final assignedOrdersStream = ref.watch(
      riderAssignedOrdersProvider(rider.id),
    );

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColorsDark.surface,
            expandedHeight: 180.h,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context, ref, rider),
            ),
          ),

          // Current Active Order
          if (rider.currentOrderId != null)
            SliverToBoxAdapter(
              child: _buildActiveOrderBanner(context, ref, rider),
            ),

          // Available Assigned Orders
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
              child: Text(
                rider.currentOrderId != null
                    ? 'Pending Orders'
                    : 'Assigned Orders',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          assignedOrdersStream.when(
            data: (orders) {
              // Filter out current active order
              final pending =
                  orders
                      .where(
                        (o) =>
                            o.id != rider.currentOrderId &&
                            o.status == OrderStatus.outForDelivery,
                      )
                      .toList();

              if (pending.isEmpty) {
                return SliverToBoxAdapter(child: _buildNoOrdersState());
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildOrderCard(context, ref, pending[index], rider),
                  childCount: pending.length,
                ),
              );
            },
            loading:
                () => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: const CircularProgressIndicator(
                        color: AppColorsDark.primary,
                      ),
                    ),
                  ),
                ),
            error:
                (e, _) =>
                    SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, RiderModel rider) {
    final isOnline = rider.status == RiderStatus.available;

    return Container(
      decoration: const BoxDecoration(gradient: AppColorsDark.primaryGradient),
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: AppColorsDark.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rider.name.substring(0, 1).toUpperCase(),
                    style: AppTextStyles.headlineSmall().copyWith(
                      color: AppColorsDark.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Name & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${rider.name.split(' ').first}! 👋',
                      style: AppTextStyles.titleLarge().copyWith(
                        color: AppColorsDark.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color:
                                isOnline
                                    ? AppColorsDark.success
                                    : AppColorsDark.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Online/Offline Toggle
              GestureDetector(
                onTap: () => _toggleStatus(context, ref, rider),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOnline
                            ? AppColorsDark.success
                            : AppColorsDark.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    isOnline ? 'Go Offline' : 'Go Online',
                    style: AppTextStyles.labelMedium().copyWith(
                      color: AppColorsDark.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderBanner(
    BuildContext context,
    WidgetRef ref,
    RiderModel rider,
  ) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsDark.primary,
            AppColorsDark.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.primary.withOpacity(0.3),
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
              Icons.delivery_dining,
              color: AppColorsDark.white,
              size: 32.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Delivery',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Order #${rider.currentOrderId!.substring(rider.currentOrderId!.length - 6)}',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => RiderActiveDeliveryScreen(
                        orderId: rider.currentOrderId!,
                        riderId: rider.id,
                      ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDark.white,
              foregroundColor: AppColorsDark.primary,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            ),
            child: Text(
              'View',
              style: AppTextStyles.button().copyWith(
                color: AppColorsDark.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    RiderModel rider,
  ) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
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
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColorsDark.primary.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 6)}',
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'PKR ${order.deliveryFee.toInt()} delivery fee',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Store
                _buildInfoRow(
                  icon: Icons.store,
                  label: 'Pickup from',
                  value: order.storeName,
                  color: AppColorsDark.primary,
                ),
                SizedBox(height: 12.h),

                // Customer
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Deliver to',
                  value: order.userName,
                  color: AppColorsDark.info,
                ),
                SizedBox(height: 12.h),

                // Address
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Address',
                  value:
                      '${order.deliveryAddress.addressLine1}, ${order.deliveryAddress.area}',
                  color: AppColorsDark.error,
                ),
                SizedBox(height: 12.h),

                // Items + Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildChip(
                      '${order.items.length} items',
                      AppColorsDark.warning,
                    ),
                    _buildChip(
                      order.paymentMethod == PaymentMethod.cod
                          ? 'Collect PKR ${order.total.toInt()}'
                          : 'Online Paid',
                      order.paymentMethod == PaymentMethod.cod
                          ? AppColorsDark.error
                          : AppColorsDark.success,
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Accept Button
                if (rider.currentOrderId == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(context, ref, order, rider),
                      icon: Icon(Icons.check, size: 20.sp),
                      label: const Text('Accept Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsDark.success,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColorsDark.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColorsDark.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Complete current delivery first',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.warning,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
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
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, size: 14.sp, color: color),
        ),
        SizedBox(width: 10.w),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall().copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNoOrdersState() {
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: const BoxDecoration(
              color: AppColorsDark.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delivery_dining,
              size: 64.sp,
              color: AppColorsDark.textTertiary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Orders Yet',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Stay online to receive new delivery orders',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    RiderModel rider,
  ) async {
    final newStatus =
        rider.status == RiderStatus.available
            ? RiderStatus.offline
            : RiderStatus.available;

    final success = await ref
        .read(ridersProvider.notifier)
        .toggleAvailability(rider.id, newStatus);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'You are now ${newStatus.name}'
                : 'Failed to update status',
          ),
          backgroundColor:
              success ? AppColorsDark.success : AppColorsDark.error,
        ),
      );
    }
  }

  Future<void> _acceptOrder(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    RiderModel rider,
  ) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Accept Order?',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Text(
              'Accept delivery for Order #${order.id.substring(order.id.length - 6)}?\n\nDelivery fee: PKR ${order.deliveryFee.toInt()}',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.success,
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await ref
          .read(ridersProvider.notifier)
          .acceptOrder(rider.id, order.id);

      if (context.mounted) {
        if (success) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => RiderActiveDeliveryScreen(
                    orderId: order.id,
                    riderId: rider.id,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to accept order'),
              backgroundColor: AppColorsDark.error,
            ),
          );
        }
      }
    }
  }
}
