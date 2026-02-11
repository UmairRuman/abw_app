// lib/features/admin/presentation/screens/orders/admin_order_details_screen.dart

import 'package:abw_app/features/admin/presentation/screens/orders/widgets/assign_rider_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../orders/presentation/providers/orders_provider.dart';
import '../../../../orders/data/models/order_model.dart';
import '../../../../orders/domain/entities/order_entity.dart';
import '../../../../orders/presentation/widgets/order_status_timeline.dart';
import '../../../../stores/presentation/providers/stores_provider.dart';

class AdminOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailsScreen({required this.orderId, super.key});

  @override
  ConsumerState<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState
    extends ConsumerState<AdminOrderDetailsScreen> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).getOrderById(widget.orderId);
    });
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
        actions: [
          if (ordersState is OrderSingleLoaded)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOrderActions(ordersState.order),
            ),
        ],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID + Status
                _buildOrderHeader(order),
                SizedBox(height: 20.h),

                // Admin Action Buttons
                _buildAdminActions(order),
                SizedBox(height: 20.h),

                // Status Timeline
                OrderStatusTimeline(
                  currentStatus: order.status,
                  statusHistory: order.statusHistory,
                ),
                SizedBox(height: 20.h),

                // Customer Info
                _buildCustomerInfo(order),
                SizedBox(height: 20.h),

                // Delivery Address
                _buildDeliveryAddress(order),
                SizedBox(height: 20.h),

                // Order Items
                _buildOrderItems(order),
                SizedBox(height: 20.h),

                // Payment Info + Proof
                _buildPaymentSection(order),
                SizedBox(height: 20.h),

                // Price Breakdown
                _buildPriceBreakdown(order),

                // Rider Info (if assigned)
                if (order.riderId != null) ...[
                  SizedBox(height: 20.h),
                  _buildRiderInfo(order),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderHeader(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColorsDark.primaryGradient,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 8)}',
                  style: AppTextStyles.headlineSmall().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(order.createdAt),
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 8.h),
                _buildStatusChip(order.status),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total',
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.white.withOpacity(0.8),
                ),
              ),
              Text(
                'PKR ${order.total.toInt()}',
                style: AppTextStyles.headlineMedium().copyWith(
                  color: AppColorsDark.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String label;
    switch (status) {
      case OrderStatus.pending:
        color = AppColorsDark.warning;
        label = 'Pending';
        break;
      case OrderStatus.confirmed:
        color = AppColorsDark.info;
        label = 'Confirmed';
        break;
      case OrderStatus.preparing:
        color = const Color(0xFFFF6B00);
        label = 'Preparing';
        break;
      case OrderStatus.outForDelivery:
        color = AppColorsDark.primary;
        label = 'On the Way';
        break;
      case OrderStatus.delivered:
        color = AppColorsDark.success;
        label = 'Delivered';
        break;
      case OrderStatus.cancelled:
        color = AppColorsDark.error;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColorsDark.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColorsDark.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall().copyWith(
          color: AppColorsDark.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAdminActions(OrderModel order) {
    final nextStatus = _getNextStatus(order.status);

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
            'Admin Actions',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          // Update Status Button
          if (nextStatus != null &&
              order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isUpdating ? null : () => _updateStatus(order, nextStatus),
                icon: Icon(Icons.arrow_forward, size: 18.sp),
                label: Text('Move to: ${_getStatusLabel(nextStatus)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStatusColor(nextStatus),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),

          SizedBox(height: 12.h),

          // Assign Rider Button
          if (order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _isUpdating ? null : () => _showAssignRiderDialog(order),
                icon: Icon(Icons.delivery_dining, size: 18.sp),
                label: Text(
                  order.riderId == null
                      ? 'Assign Rider'
                      : 'Change Rider (${order.riderName})',
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: const BorderSide(color: AppColorsDark.primary),
                ),
              ),
            ),

          // Cancel Button (for pending/confirmed)
          if (order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _isUpdating ? null : () => _cancelOrderByAdmin(order),
                icon: Icon(Icons.cancel_outlined, size: 18.sp),
                label: const Text('Cancel Order'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: const BorderSide(color: AppColorsDark.error),
                  foregroundColor: AppColorsDark.error,
                ),
              ),
            ),
          ],
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
            children: [
              Icon(Icons.person, color: AppColorsDark.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Customer Information',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsDark.border),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.person_outline, 'Name', order.userName),
          SizedBox(height: 8.h),
          _buildInfoRow(Icons.phone, 'Phone', order.userPhone),
          SizedBox(height: 8.h),
          _buildInfoRow(Icons.store, 'Store', order.storeName),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColorsDark.textSecondary),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall().copyWith(
            color: AppColorsDark.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddress(OrderModel order) {
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
              Icon(
                Icons.location_on,
                color: AppColorsDark.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Delivery Address',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsDark.border),
          SizedBox(height: 12.h),
          Text(
            order.deliveryAddress.name,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            order.deliveryAddress.phone,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${order.deliveryAddress.addressLine1}, ${order.deliveryAddress.area}, ${order.deliveryAddress.city}',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
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
          Text(
            'Order Items (${order.items.length})',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          ...order.items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child:
                        item.productImage.isNotEmpty
                            ? Image.network(
                              item.productImage,
                              width: 60.w,
                              height: 60.w,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 60.w,
                                    height: 60.w,
                                    color: AppColorsDark.surfaceContainer,
                                    child: const Icon(
                                      Icons.fastfood,
                                      color: AppColorsDark.textTertiary,
                                    ),
                                  ),
                            )
                            : Container(
                              width: 60.w,
                              height: 60.w,
                              color: AppColorsDark.surfaceContainer,
                              child: const Icon(
                                Icons.fastfood,
                                color: AppColorsDark.textTertiary,
                              ),
                            ),
                  ),
                  SizedBox(width: 12.w),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Qty: ${item.quantity} × PKR ${item.price.toInt()}',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Total
                  Text(
                    'PKR ${item.total.toInt()}',
                    style: AppTextStyles.titleSmall().copyWith(
                      color: AppColorsDark.primary,
                      fontWeight: FontWeight.bold,
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

  Widget _buildPaymentSection(OrderModel order) {
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
              Icon(Icons.payment, color: AppColorsDark.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Payment Details',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsDark.border),
          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Method',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              Text(
                _getPaymentMethodName(order.paymentMethod),
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              _buildPaymentStatusBadge(order.paymentStatus),
            ],
          ),

          // Payment Proof Screenshot
          if (order.paymentProofUrl != null) ...[
            SizedBox(height: 16.h),
            const Divider(color: AppColorsDark.border),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Proof',
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Verify Payment Button
                if (order.paymentStatus == PaymentStatus.pending)
                  ElevatedButton.icon(
                    onPressed: () => _verifyPayment(order),
                    icon: Icon(Icons.verified, size: 16.sp),
                    label: const Text('Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsDark.success,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),

            // Screenshot image
            GestureDetector(
              onTap: () => _showFullScreenImage(order.paymentProofUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  order.paymentProofUrl!,
                  width: double.infinity,
                  height: 250.h,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 250.h,
                      color: AppColorsDark.surfaceContainer,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColorsDark.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: 100.h,
                        color: AppColorsDark.surfaceContainer,
                        child: Center(
                          child: Text(
                            'Failed to load image',
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.error,
                            ),
                          ),
                        ),
                      ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tap to view full screen',
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBadge(PaymentStatus status) {
    Color color;
    String text;
    switch (status) {
      case PaymentStatus.pending:
        color = AppColorsDark.warning;
        text = 'Pending Verification';
        break;
      case PaymentStatus.completed:
        color = AppColorsDark.success;
        text = 'Verified';
        break;
      case PaymentStatus.failed:
        color = AppColorsDark.error;
        text = 'Failed';
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall().copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(OrderModel order) {
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
            'Bill Summary',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildPriceRow('Subtotal', order.subtotal),
          SizedBox(height: 8.h),
          _buildPriceRow('Delivery Fee', order.deliveryFee),
          if (order.discount > 0) ...[
            SizedBox(height: 8.h),
            _buildPriceRow('Discount', order.discount, isDiscount: true),
          ],
          SizedBox(height: 12.h),
          const Divider(color: AppColorsDark.border),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.titleLarge().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'PKR ${order.total.toInt()}',
                style: AppTextStyles.titleLarge().copyWith(
                  color: AppColorsDark.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textSecondary,
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}PKR ${amount.abs().toInt()}',
          style: AppTextStyles.bodyMedium().copyWith(
            color:
                isDiscount ? AppColorsDark.success : AppColorsDark.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRiderInfo(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColorsDark.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delivery_dining,
              color: AppColorsDark.primary,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Rider',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  order.riderName ?? 'Unknown',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- ACTION METHODS ----

  void _showOrderActions(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorsDark.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order Actions',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                ...OrderStatus.values
                    .where(
                      (s) => s != order.status && s != OrderStatus.cancelled,
                    )
                    .map(
                      (status) => ListTile(
                        leading: Icon(
                          Icons.arrow_forward_ios,
                          color: _getStatusColor(status),
                          size: 18.sp,
                        ),
                        title: Text(
                          'Set as ${_getStatusLabel(status)}',
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.textPrimary,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _updateStatus(order, status);
                        },
                      ),
                    ),
              ],
            ),
          ),
    );
  }

  Future<void> _updateStatus(OrderModel order, OrderStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final success = await ref
          .read(ordersProvider.notifier)
          .updateOrderStatus(
            order.id,
            newStatus,
            'Status updated by admin',
            'admin',
          );

      if (success && mounted) {
        ref.read(ordersProvider.notifier).getOrderById(order.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_getStatusLabel(newStatus)}'),
            backgroundColor: AppColorsDark.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _verifyPayment(OrderModel order) async {
    setState(() => _isUpdating = true);
    try {
      await ref
          .read(ordersProvider.notifier)
          .updatePaymentStatus(order.id, PaymentStatus.completed);

      if (mounted) {
        ref.read(ordersProvider.notifier).getOrderById(order.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verified successfully'),
            backgroundColor: AppColorsDark.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _cancelOrderByAdmin(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Cancel Order?',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to cancel this order?',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                ),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      _updateStatus(order, OrderStatus.cancelled);
    }
  }

  void _showAssignRiderDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AssignRiderDialog(order: order),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: InteractiveViewer(child: Image.network(imageUrl)),
              ),
            ),
      ),
    );
  }

  OrderStatus? _getNextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.outForDelivery;
      case OrderStatus.outForDelivery:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColorsDark.warning;
      case OrderStatus.confirmed:
        return AppColorsDark.info;
      case OrderStatus.preparing:
        return const Color(0xFFFF6B00);
      case OrderStatus.outForDelivery:
        return AppColorsDark.primary;
      case OrderStatus.delivered:
        return AppColorsDark.success;
      case OrderStatus.cancelled:
        return AppColorsDark.error;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cod:
        return 'Cash on Delivery';
      case PaymentMethod.jazzcash:
        return 'JazzCash';
      case PaymentMethod.easypaisa:
        return 'EasyPaisa';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
}
