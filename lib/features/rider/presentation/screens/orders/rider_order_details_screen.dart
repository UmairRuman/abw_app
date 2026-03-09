// lib/features/rider/presentation/screens/orders/rider_order_details_screen.dart
// UPDATED:
//   ✅ Special instructions HIDDEN from rider
//   ✅ Full status control: preparing → outForDelivery → delivered
//   ✅ Cash check-in button for COD orders after delivery
//   ✅ _buildMap() + _buildDistanceCard() replaced with OrderMapWidget
//      (real OSRM road route, distance+ETA chips, address card, directions button)

import 'package:abw_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../core/widgets/order_map_widget.dart'; // ✅ replaces flutter_map + location_service imports
import '../../../../orders/presentation/providers/orders_provider.dart';
import '../../../../orders/data/models/order_model.dart';
import '../../../../orders/domain/entities/order_entity.dart';
import '../../../../riders/presentation/providers/riders_provider.dart';

class RiderOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;
  const RiderOrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<RiderOrderDetailsScreen> createState() =>
      _RiderOrderDetailsScreenState();
}

class _RiderOrderDetailsScreenState
    extends ConsumerState<RiderOrderDetailsScreen> {
  bool _isUpdatingStatus = false;
  bool _isCashingIn = false;

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
          'Order Details',
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
              ? _buildOrderDetails(ordersState.order)
              : const Center(child: Text('Failed to load order')),
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ✅ REPLACES _buildMap() + _buildDistanceCard()
                // OrderMapWidget handles: real road route via OSRM, distance +
                // ETA overlay chips, pickup/delivery address card, and a
                // Get Directions button that opens Google Maps / OSM.
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: OrderMapWidget(order: order, mapHeight: 250),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
                  child: Column(
                    children: [
                      // ✅ Status stepper shown to rider
                      _buildStatusStepper(order),
                      SizedBox(height: 16.h),
                      _buildStoreInfo(order),
                      SizedBox(height: 16.h),
                      _buildCustomerInfo(order),
                      SizedBox(height: 16.h),
                      _buildOrderItems(order),
                      SizedBox(height: 16.h),
                      _buildPaymentInfo(order),
                      // ✅ SPECIAL INSTRUCTIONS deliberately NOT shown to rider
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomActions(order),
      ],
    );
  }

  // ── Status Stepper ────────────────────────────────────────────────────────

  /// Shows the rider where the order currently is in the lifecycle.
  Widget _buildStatusStepper(OrderModel order) {
    final steps = [
      _StatusStep(
        status: OrderStatus.confirmed,
        label: 'Confirmed',
        icon: Icons.check_circle_outline,
      ),
      _StatusStep(
        status: OrderStatus.preparing,
        label: 'Preparing',
        icon: Icons.restaurant,
      ),
      _StatusStep(
        status: OrderStatus.outForDelivery,
        label: 'Out for Delivery',
        icon: Icons.delivery_dining,
      ),
      _StatusStep(
        status: OrderStatus.delivered,
        label: 'Delivered',
        icon: Icons.task_alt,
      ),
    ];

    final currentIndex = steps.indexWhere((s) => s.status == order.status);

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
            'Order Progress',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children:
                steps.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final step = entry.value;
                  final isDone = idx < currentIndex;
                  final isCurrent = idx == currentIndex;
                  final color =
                      isDone || isCurrent
                          ? AppColorsDark.primary
                          : AppColorsDark.textTertiary;

                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 32.w,
                                height: 32.w,
                                decoration: BoxDecoration(
                                  color:
                                      isCurrent
                                          ? AppColorsDark.primary
                                          : isDone
                                          ? AppColorsDark.success
                                          : AppColorsDark.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDone ? Icons.check : step.icon,
                                  color:
                                      isDone || isCurrent
                                          ? AppColorsDark.white
                                          : AppColorsDark.textTertiary,
                                  size: 16.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                step.label,
                                style: AppTextStyles.bodySmall().copyWith(
                                  color: color,
                                  fontWeight:
                                      isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize: 9.sp,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        if (idx < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color:
                                  idx < currentIndex
                                      ? AppColorsDark.success
                                      : AppColorsDark.border,
                              margin: EdgeInsets.only(bottom: 20.h),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Info Cards ────────────────────────────────────────────────────────────

  Widget _buildStoreInfo(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Row(
        children: [
          Icon(Icons.store, color: AppColorsDark.success, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            'Pickup: ',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          Text(
            order.storeName,
            style: AppTextStyles.bodyLarge().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(OrderModel order) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: AppColorsDark.info, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Customer Details',
                    style: AppTextStyles.titleSmall().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _callCustomer(order.userPhone),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColorsDark.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.phone,
                    color: AppColorsDark.success,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            order.userName,
            style: AppTextStyles.bodyLarge().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            order.userPhone,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          const Divider(color: AppColorsDark.border),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.location_on, color: AppColorsDark.error, size: 16.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  order.deliveryAddress.getShortAddress(),
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          // ✅ FEATURE #4: Special instructions NOT shown to rider (intentionally omitted)
        ],
      ),
    );
  }

  Widget _buildOrderItems(OrderModel order) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Items',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColorsDark.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${order.items.length} items',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...order.items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      item.productName,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(OrderModel order) {
    final isCOD = order.paymentMethod == PaymentMethod.cod;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            isCOD
                ? AppColorsDark.warning.withOpacity(0.1)
                : AppColorsDark.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              isCOD
                  ? AppColorsDark.warning.withOpacity(0.3)
                  : AppColorsDark.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCOD ? Icons.money : Icons.check_circle,
            color: isCOD ? AppColorsDark.warning : AppColorsDark.success,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCOD ? 'Collect Cash' : 'Already Paid',
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isCOD
                      ? 'Collect PKR ${order.total.toInt()} from customer'
                      : 'Payment completed online',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'PKR ${order.total.toInt()}',
            style: AppTextStyles.titleLarge().copyWith(
              color: isCOD ? AppColorsDark.warning : AppColorsDark.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Actions ────────────────────────────────────────────────────────

  /// ✅ FEATURE #7: Full rider status control
  /// ✅ FEATURE #8: Cash check-in after delivery
  Widget _buildBottomActions(OrderModel order) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cash check-in (shown after delivery for COD)
            if (order.status == OrderStatus.delivered &&
                order.paymentMethod == PaymentMethod.cod &&
                !(order.cashCheckedIn ?? false))
              _buildCashCheckInButton(order),

            if (order.status == OrderStatus.delivered &&
                order.paymentMethod == PaymentMethod.cod &&
                (order.cashCheckedIn ?? false))
              _buildCashCheckedInBadge(order),

            // Status action buttons
            if (order.status == OrderStatus.confirmed ||
                order.status == OrderStatus.preparing)
              _buildStatusActionButton(
                order: order,
                label:
                    order.status == OrderStatus.confirmed
                        ? 'Mark as Preparing'
                        : 'Mark as Out for Delivery',
                nextStatus:
                    order.status == OrderStatus.confirmed
                        ? OrderStatus.preparing
                        : OrderStatus.outForDelivery,
                icon:
                    order.status == OrderStatus.confirmed
                        ? Icons.restaurant
                        : Icons.delivery_dining,
                color: AppColorsDark.warning,
              ),

            if (order.status == OrderStatus.outForDelivery)
              _buildStatusActionButton(
                order: order,
                label: 'Mark as Delivered',
                nextStatus: OrderStatus.delivered,
                icon: Icons.task_alt,
                color: AppColorsDark.primary,
              ),

            if (order.status == OrderStatus.delivered &&
                order.paymentMethod != PaymentMethod.cod)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColorsDark.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColorsDark.success,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Order Delivered Successfully',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            if (order.status == OrderStatus.cancelled)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColorsDark.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'This order was cancelled by admin',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActionButton({
    required OrderModel order,
    required String label,
    required OrderStatus nextStatus,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _isUpdatingStatus ? null : () => _updateStatus(order, nextStatus),
        icon:
            _isUpdatingStatus
                ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColorsDark.white,
                  ),
                )
                : Icon(icon, size: 20.sp),
        label: Text(
          _isUpdatingStatus ? 'Updating...' : label,
          style: AppTextStyles.button(),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
    );
  }

  Widget _buildCashCheckInButton(OrderModel order) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isCashingIn ? null : () => _cashCheckIn(order),
          icon:
              _isCashingIn
                  ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColorsDark.white,
                    ),
                  )
                  : Icon(Icons.payments, size: 20.sp),
          label: Text(
            _isCashingIn
                ? 'Processing...'
                : 'Check-in Cash (PKR ${order.total.toInt()} received)',
            style: AppTextStyles.button(),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsDark.success,
            padding: EdgeInsets.symmetric(vertical: 16.h),
          ),
        ),
      ),
    );
  }

  Widget _buildCashCheckedInBadge(OrderModel order) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColorsDark.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsDark.success.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, color: AppColorsDark.success, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Cash PKR ${order.total.toInt()} — Checked In ✓',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone dialer'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(OrderModel order, OrderStatus newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Update Status',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Text(
              'Mark order as "${newStatus.name}"?',
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
                  backgroundColor: AppColorsDark.primary,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isUpdatingStatus = true);
    try {
      final success = await ref
          .read(ordersProvider.notifier)
          .updateOrderStatus(
            order.id,
            newStatus,
            'Status updated by rider',
            'rider',
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Status updated to ${newStatus.name}'),
            backgroundColor: AppColorsDark.success,
          ),
        );
        await ref.read(ordersProvider.notifier).getOrderById(order.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _cashCheckIn(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Confirm Cash Received',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Text(
              'Confirm you received PKR ${order.total.toInt()} cash from the customer?\n\nAdmin will be notified.',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not yet'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.success,
                ),
                child: const Text('Yes, Received'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isCashingIn = true);
    try {
      // Get the current rider ID from auth
      final authState = ref.read(authProvider);
      if (authState is! Authenticated) return;

      final success = await ref
          .read(ridersProvider.notifier)
          .cashCheckIn(authState.user.id, order.id, order.total);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cash check-in confirmed! Admin notified.'),
            backgroundColor: AppColorsDark.success,
          ),
        );
        await ref.read(ordersProvider.notifier).getOrderById(order.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCashingIn = false);
    }
  }
}

// ── Helper classes ────────────────────────────────────────────────────────────

class _StatusStep {
  final OrderStatus status;
  final String label;
  final IconData icon;
  const _StatusStep({
    required this.status,
    required this.label,
    required this.icon,
  });
}
