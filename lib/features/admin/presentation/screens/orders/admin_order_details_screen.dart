// lib/features/admin/presentation/screens/orders/admin_order_details_screen.dart
// ADMIN ORDER DETAILS WITH CANCELLATION

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../orders/data/models/order_model.dart';
import '../../../../orders/domain/entities/order_entity.dart';
import '../../../../orders/presentation/providers/orders_provider.dart';
import '../../../../cart/data/models/cart_item_model.dart';

class AdminOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailsScreen({required this.orderId, super.key});

  @override
  ConsumerState<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState
    extends ConsumerState<AdminOrderDetailsScreen> {
  bool _isProcessing = false;

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
          // ✅ More options menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'cancel' && ordersState is OrderSingleLoaded) {
                _showCancelOrderDialog(ordersState.order);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: AppColorsDark.error),
                        SizedBox(width: 8),
                        Text('Cancel Order'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          ordersState is OrdersLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              )
              : ordersState is OrderSingleLoaded
              ? _buildOrderDetails(ordersState.order)
              : ordersState is OrdersError
              ? _buildErrorState(ordersState.message)
              : const Center(child: Text('Unable to load order')),
    );
  }

  String _toJpgUrl(String url) {
    if (!url.contains('cloudinary.com')) return url;
    if (url.contains('f_auto')) return url.replaceAll('f_auto', 'f_jpg');
    if (url.contains('f_png')) return url.replaceAll('f_png', 'f_jpg');
    if (url.contains('f_webp')) return url.replaceAll('f_webp', 'f_jpg');
    // No format token present — inject f_jpg after /upload/
    return url.replaceFirstMapped(
      RegExp(r'(/image/upload/)'),
      (m) => '${m[1]}f_jpg/',
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    final canCancel = _canCancelOrder(order.status);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Card
                _buildOrderStatusCard(order),
                SizedBox(height: 16.h),

                // Customer Info
                _buildCustomerInfo(order),
                SizedBox(height: 16.h),

                // Rider Info (if assigned)
                if (order.riderId != null) _buildRiderInfo(order),
                if (order.riderId != null) SizedBox(height: 16.h),

                // Delivery Address
                _buildDeliveryAddress(order),
                SizedBox(height: 16.h),

                // Order Items
                _buildOrderItems(order),
                SizedBox(height: 16.h),

                // Payment Info
                _buildPaymentInfo(order),
                SizedBox(height: 16.h),

                // Price Breakdown
                _buildPriceBreakdown(order),
                SizedBox(height: 16.h),

                // Special Instructions
                if (order.specialInstructions != null &&
                    order.specialInstructions!.isNotEmpty)
                  _buildSpecialInstructions(order.specialInstructions!),

                // Cancellation Info (if cancelled)
                if (order.status == OrderStatus.cancelled &&
                    order.cancellationReason != null)
                  _buildCancellationInfo(order),

                if (order.status == OrderStatus.cancelled)
                  SizedBox(height: 16.h),

                // ✅ Show rider refusal info if order was refused before
                if (order.riderRefusalReason != null)
                  _buildRiderRefusalInfo(order),
              ],
            ),
          ),
        ),

        // ✅ Action Buttons
        if (_canCancelOrder(order.status)) _buildActionButtons(order),
      ],
    );
  }

  // ✅ Check if order can be cancelled
  bool _canCancelOrder(OrderStatus status) {
    return status == OrderStatus.pending ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.preparing ||
        status == OrderStatus.outForDelivery; // ✅ REMOVED: OrderStatus.ready
  }

  // ✅ Action Buttons
  Widget _buildActionButtons(OrderModel order) {
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
        child: ElevatedButton(
          onPressed: _isProcessing ? null : () => _showCancelOrderDialog(order),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 56.h),
            backgroundColor: AppColorsDark.error,
          ),
          child:
              _isProcessing
                  ? SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColorsDark.white,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel),
                      SizedBox(width: 8.w),
                      Text(
                        'Cancel Order',
                        style: AppTextStyles.button().copyWith(fontSize: 16.sp),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  // ✅ Cancel Order Dialog
  void _showCancelOrderDialog(OrderModel order) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            icon: Icon(
              Icons.warning_amber_rounded,
              color: AppColorsDark.error,
              size: 48.sp,
            ),
            title: Text(
              'Cancel Order',
              style: AppTextStyles.titleLarge().copyWith(
                color: AppColorsDark.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(order.id.length - 8)}',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Cancellation Reason',
                    style: AppTextStyles.labelMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a reason';
                      }
                      if (value.trim().length < 10) {
                        return 'Reason must be at least 10 characters';
                      }
                      return null;
                    },
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Customer requested cancellation',
                      filled: true,
                      fillColor: AppColorsDark.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColorsDark.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColorsDark.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColorsDark.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColorsDark.error,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColorsDark.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColorsDark.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This action will:',
                          style: AppTextStyles.labelMedium().copyWith(
                            color: AppColorsDark.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _buildConsequenceItem(
                          'Update order status to "Cancelled"',
                        ),
                        _buildConsequenceItem('Notify customer'),
                        if (order.riderId != null)
                          _buildConsequenceItem('Notify assigned rider'),
                        _buildConsequenceItem('Cannot be undone'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  reasonController.dispose();
                  Navigator.pop(context);
                },
                child: Text(
                  'Keep Order',
                  style: TextStyle(color: AppColorsDark.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final reason = reasonController.text.trim();
                    reasonController.dispose();
                    Navigator.pop(context);
                    _handleCancelOrder(order.id, reason);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                ),
                child: const Text('Cancel Order'),
              ),
            ],
          ),
    );
  }

  Widget _buildConsequenceItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16.sp,
            color: AppColorsDark.warning,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Handle Cancel Order
  Future<void> _handleCancelOrder(String orderId, String reason) async {
    setState(() => _isProcessing = true);

    try {
      final success = await ref
          .read(ordersProvider.notifier)
          .cancelOrder(orderId, reason);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12.w),
                const Text('Order cancelled successfully'),
              ],
            ),
            backgroundColor: AppColorsDark.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reload order
        await ref.read(ordersProvider.notifier).getOrderById(orderId);
      } else {
        throw Exception('Failed to cancel order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColorsDark.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ✅ Cancellation Info Display
  Widget _buildCancellationInfo(OrderModel order) {
    // ✅ Check for cancellationReason field (not just status)
    if (order.status != OrderStatus.cancelled ||
        order.cancellationReason == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel, color: AppColorsDark.error, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Order Cancelled',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsDark.error),
          SizedBox(height: 12.h),
          // ✅ Show cancelled by
          if (order.cancelledBy != null) ...[
            Text(
              'Cancelled by: ${order.cancelledBy!.toUpperCase()}',
              style: AppTextStyles.labelSmall().copyWith(
                color: AppColorsDark.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
          ],
          // ✅ Show reason from cancellationReason field
          Text(
            'Reason:',
            style: AppTextStyles.labelSmall().copyWith(
              color: AppColorsDark.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            order.cancellationReason!,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.error,
            ),
          ),
          // ✅ Show timestamp from cancelledAt field
          if (order.cancelledAt != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Cancelled at: ${DateFormat('MMM d, yyyy • h:mm a').format(order.cancelledAt!)}',
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ Optional: Show rider refusal info if order was refused
  Widget _buildRiderRefusalInfo(OrderModel order) {
    if (order.riderRefusalReason == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: AppColorsDark.warning,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Rider Refusal History',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsDark.warning),
          SizedBox(height: 12.h),
          Text(
            'Previous rider refused this order:',
            style: AppTextStyles.labelSmall().copyWith(
              color: AppColorsDark.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            order.riderRefusalReason!,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.warning,
            ),
          ),
          if (order.riderRefusedAt != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Refused at: ${DateFormat('MMM d, yyyy • h:mm a').format(order.riderRefusedAt!)}',
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ... (Keep all other existing widgets: _buildOrderStatusCard, _buildCustomerInfo,
  // _buildRiderInfo, _buildDeliveryAddress, _buildOrderItems, _buildPaymentInfo,
  // _buildPriceBreakdown, _buildSpecialInstructions, _buildErrorState)

  Widget _buildOrderStatusCard(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: _getStatusGradient(order.status),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(order.status).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      DateFormat(
                        'MMM d, yyyy • h:mm a',
                      ).format(order.createdAt),
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColorsDark.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: AppTextStyles.labelMedium().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
          _buildInfoRow('Name', order.userName),
          SizedBox(height: 8.h),
          _buildInfoRow('Phone', order.userPhone),
        ],
      ),
    );
  }

  Widget _buildRiderInfo(OrderModel order) {
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
                Icons.delivery_dining,
                color: AppColorsDark.success,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Delivery Rider',
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
          _buildInfoRow('Name', order.riderName ?? 'Unknown'),
          SizedBox(height: 8.h),
          _buildInfoRow('Phone', order.riderPhone ?? 'Not available'),
        ],
      ),
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
            '${order.deliveryAddress.addressLine1}, ${order.deliveryAddress.area}, ${order.deliveryAddress.city}',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textPrimary,
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
          ...order.items.map((item) => _buildOrderItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(CartItemModel item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Details ────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + qty
                Text(
                  '${item.quantity}x ${item.productName}',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // ✅ Selected size variant
                if (item.selectedVariant != null) ...[
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 12.sp,
                        color: AppColorsDark.primary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Size: ${item.selectedVariant!.name}',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                // ✅ Selected addons
                if (item.selectedAddons.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 12.sp,
                        color: AppColorsDark.success,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          item.selectedAddons.map((a) => a.name).join(', '),
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // ✅ Per-item special instructions
                if (item.specialInstructions != null &&
                    item.specialInstructions!.isNotEmpty) ...[
                  SizedBox(height: 5.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsDark.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppColorsDark.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 12.sp,
                          color: AppColorsDark.warning,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            item.specialInstructions!,
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.warning,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Price ─────────────────────────────────────────────────────────
          // ✅ FIXED: was item.total (could be stale base price).
          //    discountedPrice holds the effective variant price from addToCart.
          Text(
            'PKR ${(item.discountedPrice * item.quantity).toInt()}',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(OrderModel order) {
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
          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.payment, color: AppColorsDark.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Payment',
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

          // ── Method ────────────────────────────────────────────────────────
          _buildInfoRow('Method', _getPaymentMethodName(order.paymentMethod)),
          SizedBox(height: 8.h),

          // ── Payment Status badge ──────────────────────────────────────────
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

          // ── Payment Proof Screenshot ──────────────────────────────────────
          // ✅ FIX: This block was completely absent in the updated screen.
          //    Re-added with _toJpgUrl to fix Android WebP/AVIF decode failure.
          if (order.paymentProofUrl != null &&
              order.paymentProofUrl!.isNotEmpty) ...[
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
                // Verify button — only shown when payment is pending
                if (order.paymentStatus == PaymentStatus.pending)
                  ElevatedButton.icon(
                    onPressed:
                        _isProcessing
                            ? null
                            : () => _handleVerifyPayment(order),
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

            GestureDetector(
              onTap:
                  () => _showFullScreenImage(_toJpgUrl(order.paymentProofUrl!)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  _toJpgUrl(order.paymentProofUrl!), // ✅ Force JPEG for Android
                  width: double.infinity,
                  height: 250.h,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 250.h,
                      color: AppColorsDark.surfaceContainer,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppColorsDark.primary,
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Loading payment proof...',
                              style: AppTextStyles.bodySmall().copyWith(
                                color: AppColorsDark.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: 100.h,
                        decoration: BoxDecoration(
                          color: AppColorsDark.surfaceContainer,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: AppColorsDark.error,
                              size: 32.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Failed to load image',
                              style: AppTextStyles.bodySmall().copyWith(
                                color: AppColorsDark.error,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            GestureDetector(
                              onTap:
                                  () => _showFullScreenImage(
                                    order.paymentProofUrl!,
                                  ),
                              child: Text(
                                'Tap to try original URL',
                                style: AppTextStyles.bodySmall().copyWith(
                                  color: AppColorsDark.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Tap image to view full screen',
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

  /// Opens the image full-screen with pinch-to-zoom
  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'Payment Proof',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: Center(
                child: InteractiveViewer(child: Image.network(imageUrl)),
              ),
            ),
      ),
    );
  }

  /// Verify payment and refresh order
  Future<void> _handleVerifyPayment(OrderModel order) async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({'paymentStatus': 'completed'});

      if (mounted) {
        await ref.read(ordersProvider.notifier).getOrderById(order.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verified successfully'),
            backgroundColor: AppColorsDark.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify: ${e.toString()}'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
        children: [
          _buildPriceRow('Subtotal', order.subtotal),
          SizedBox(height: 8.h),
          _buildPriceRow('Delivery Fee', order.deliveryFee),
          if (order.discount > 0) ...[
            SizedBox(height: 8.h),
            _buildPriceRow('Discount', -order.discount, isDiscount: true),
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

  Widget _buildSpecialInstructions(String instructions) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_alt_outlined,
                color: AppColorsDark.info,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Special Instructions',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            instructions,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
          value,
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColorsDark.error),
          SizedBox(height: 16.h),
          Text(
            message,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColorsDark.warning;
      case OrderStatus.confirmed:
        return AppColorsDark.info;
      case OrderStatus.preparing:
        return AppColorsDark.primary;
      case OrderStatus.outForDelivery:
        return AppColorsDark.info;
      case OrderStatus.delivered:
        return AppColorsDark.success;
      case OrderStatus.cancelled:
        return AppColorsDark.error;
    }
  }

  LinearGradient _getStatusGradient(OrderStatus status) {
    final color = _getStatusColor(status);
    return LinearGradient(
      colors: [color, color.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.preparing:
        return 'PREPARING';

      case OrderStatus.outForDelivery:
        return 'OUT FOR DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
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
