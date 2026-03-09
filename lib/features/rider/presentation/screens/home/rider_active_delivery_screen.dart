// lib/features/rider/presentation/screens/home/rider_active_delivery_screen.dart
// UPDATED: OrderMapWidget integrated at top of screen

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../core/widgets/order_map_widget.dart';
import '../../../../orders/presentation/providers/orders_provider.dart';
import '../../../../orders/data/models/order_model.dart';
import '../../../../orders/domain/entities/order_entity.dart';
import '../../../../riders/presentation/providers/riders_provider.dart';

class RiderActiveDeliveryScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String riderId;

  const RiderActiveDeliveryScreen({
    required this.orderId,
    required this.riderId,
    super.key,
  });

  @override
  ConsumerState<RiderActiveDeliveryScreen> createState() =>
      _RiderActiveDeliveryScreenState();
}

class _RiderActiveDeliveryScreenState
    extends ConsumerState<RiderActiveDeliveryScreen> {
  bool _isMarkingDelivered = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(ordersProvider.notifier).getOrderById(widget.orderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Active Delivery',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body:
          ordersState is OrdersLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              )
              : ordersState is OrderSingleLoaded
              ? _buildContent(ordersState.order)
              : const Center(child: Text('Unable to load order')),
    );
  }

  Widget _buildContent(OrderModel order) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Status Card
                _buildStatusCard(order),
                SizedBox(height: 20.h),

                // ✅ MAP — full road route + address card + directions button
                OrderMapWidget(order: order, mapHeight: 270),
                SizedBox(height: 20.h),

                // Pickup Details
                _buildSection(
                  title: 'Pickup From',
                  icon: Icons.store,
                  color: AppColorsDark.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.storeName,
                        style: AppTextStyles.titleMedium().copyWith(
                          color: AppColorsDark.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Delivery Details
                _buildSection(
                  title: 'Deliver To',
                  icon: Icons.location_on,
                  color: AppColorsDark.error,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.userName,
                        style: AppTextStyles.titleSmall().copyWith(
                          color: AppColorsDark.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        order.userPhone,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '${order.deliveryAddress.addressLine1}, '
                        '${order.deliveryAddress.area}, '
                        '${order.deliveryAddress.city}',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      OutlinedButton.icon(
                        onPressed: () => _copyPhone(context, order.userPhone),
                        icon: Icon(Icons.copy, size: 16.sp),
                        label: Text('Copy: ${order.userPhone}'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColorsDark.primary),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Order Items Summary
                _buildSection(
                  title: 'Order Items',
                  icon: Icons.shopping_bag,
                  color: AppColorsDark.warning,
                  child: Column(
                    children: [
                      ...order.items.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}x ${item.productName}',
                                  style: AppTextStyles.bodySmall().copyWith(
                                    color: AppColorsDark.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                'PKR ${item.total.toInt()}',
                                style: AppTextStyles.bodySmall().copyWith(
                                  color: AppColorsDark.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Payment Info
                _buildSection(
                  title: 'Payment',
                  icon: Icons.payment,
                  color: AppColorsDark.info,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.paymentMethod == PaymentMethod.cod
                                ? '⚠️ Collect Cash from Customer'
                                : '✅ Already Paid Online',
                            style: AppTextStyles.bodyMedium().copyWith(
                              color:
                                  order.paymentMethod == PaymentMethod.cod
                                      ? AppColorsDark.warning
                                      : AppColorsDark.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (order.paymentMethod == PaymentMethod.cod) ...[
                            SizedBox(height: 4.h),
                            Text(
                              'Amount: PKR ${order.total.toInt()}',
                              style: AppTextStyles.titleMedium().copyWith(
                                color: AppColorsDark.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // ✅ "Your Earnings" removed — riders don't see salary
                    ],
                  ),
                ),

                SizedBox(height: 80.h), // space for bottom bar
              ],
            ),
          ),
        ),

        // Bottom - Mark Delivered Button
        _buildBottomBar(order),
      ],
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildStatusCard(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsDark.primary,
            AppColorsDark.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.delivery_dining, color: AppColorsDark.white, size: 48.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Out for Delivery',
                  style: AppTextStyles.titleLarge().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Order #${order.id.substring(order.id.length - 8)}',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsDark.border),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        color: AppColorsDark.surface,
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.shadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _isMarkingDelivered ? null : () => _markDelivered(order),
          icon:
              _isMarkingDelivered
                  ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColorsDark.white,
                    ),
                  )
                  : Icon(Icons.task_alt, size: 22.sp),
          label: Text(
            _isMarkingDelivered ? 'Marking...' : 'Mark as Delivered',
            style: AppTextStyles.button().copyWith(fontSize: 16.sp),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 56.h),
            backgroundColor: AppColorsDark.success,
          ),
        ),
      ),
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone number copied!'),
        backgroundColor: AppColorsDark.success,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _markDelivered(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Mark as Delivered?',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Text(
              'Confirm that this order has been delivered to the customer.',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.success,
                ),
                child: const Text('Yes, Delivered!'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isMarkingDelivered = true);
      try {
        final success = await ref
            .read(ridersProvider.notifier)
            .markDelivered(
              widget.riderId,
              order.id,
              deliveryFee: order.deliveryFee,
              collectedCash:
                  order.paymentMethod == PaymentMethod.cod ? order.total : 0.0,
              distance: order.distance ?? 0.0,
            );

        if (mounted) {
          if (success) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Delivery completed successfully!'),
                backgroundColor: AppColorsDark.success,
              ),
            );
          } else {
            throw Exception('Failed to mark as delivered');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColorsDark.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isMarkingDelivered = false);
      }
    }
  }
}
