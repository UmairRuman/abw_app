// lib/features/admin/presentation/screens/orders/admin_order_details_screen.dart
// COMPLETE REPLACEMENT
//
// FIXES:
//  1. ✅ Cancel dispose bug — reasonController is now a STATE FIELD disposed in dispose()
//  2. ✅ Unverify payment button — reverts payment to COD
//  3. ✅ Rider payment display — shows correct status based on paymentStatus field

import 'dart:async';

import 'package:abw_app/features/admin/presentation/screens/orders/widgets/assign_rider_dialog.dart';
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

  // ✅ FIX: Controller is a STATE FIELD — Flutter manages its lifecycle.
  // Disposing it in a dialog's .then() fires during the close animation
  // while TextFormField still holds a listener → ChangeNotifier disposed crash.
  final TextEditingController _cancelReasonController = TextEditingController();
  final GlobalKey<FormState> _cancelFormKey = GlobalKey<FormState>();
  StreamSubscription<DocumentSnapshot>? _orderStream;
  OrderModel? _streamOrder;

  @override
  void initState() {
    super.initState();
    // ✅ Use a real-time stream so admin sees rider status updates instantly
    _orderStream = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          if (snapshot.exists && snapshot.data() != null) {
            final order = OrderModel.fromJson({
              'id': snapshot.id,
              ...snapshot.data()!,
            });
            setState(() => _streamOrder = order);
          }
        });
  }

  @override
  void dispose() {
    _orderStream?.cancel();
    _cancelReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'cancel' && _streamOrder != null) {
                _showCancelOrderDialog(_streamOrder!);
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
          _streamOrder == null
              ? const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              )
              : _buildOrderDetails(_streamOrder!),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MAIN LAYOUT
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildOrderDetails(OrderModel order) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderStatusCard(order),
                SizedBox(height: 16.h),
                _buildStoreInfo(order),
                SizedBox(height: 16.h),
                _buildStatusUpdateCard(order),
                SizedBox(height: 16.h),
                _buildCustomerInfo(order),
                SizedBox(height: 16.h),
                if (order.riderId != null) ...[
                  _buildRiderInfo(order),
                  SizedBox(height: 16.h),
                ],
                _buildDeliveryAddress(order),
                SizedBox(height: 16.h),
                _buildOrderItems(order),
                SizedBox(height: 16.h),
                if (order.specialInstructions != null &&
                    order.specialInstructions!.isNotEmpty) ...[
                  _buildSpecialInstructions(order.specialInstructions!),
                  SizedBox(height: 16.h),
                ],
                _buildPaymentInfo(order),
                SizedBox(height: 16.h),
                _buildPriceBreakdown(order),
                SizedBox(height: 16.h),
                if (order.status == OrderStatus.cancelled &&
                    order.cancellationReason != null)
                  _buildCancellationInfo(order),
                if (order.riderRefusalReason != null)
                  _buildRiderRefusalInfo(order),
              ],
            ),
          ),
        ),
        if (_canCancelOrder(order.status)) _buildActionButtons(order),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STATUS PROGRESSION
  // ───────────────────────────────────────────────────────────────────────────

  ({OrderStatus next, String label, Color color, IconData icon})?
  _getNextStatusAction(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return (
          next: OrderStatus.confirmed,
          label: 'Confirm Order',
          color: AppColorsDark.info,
          icon: Icons.check_circle_outline,
        );
      case OrderStatus.confirmed:
        return (
          next: OrderStatus.preparing,
          label: 'Mark as Preparing',
          color: AppColorsDark.primary,
          icon: Icons.restaurant,
        );
      case OrderStatus.preparing:
        return (
          next: OrderStatus.outForDelivery,
          label: 'Out for Delivery',
          color: AppColorsDark.info,
          icon: Icons.delivery_dining,
        );
      case OrderStatus.outForDelivery:
        return (
          next: OrderStatus.delivered,
          label: 'Mark as Delivered',
          color: AppColorsDark.success,
          icon: Icons.done_all,
        );
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STORE INFO CARD
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildStoreInfo(OrderModel order) {
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
                Icons.store_mall_directory,
                color: AppColorsDark.success,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Restaurant / Store',
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
            order.storeName.isNotEmpty
                ? order.storeName
                : 'Store name unavailable',
            style: AppTextStyles.titleLarge().copyWith(
              color:
                  order.storeName.isNotEmpty
                      ? AppColorsDark.textPrimary
                      : AppColorsDark.textTertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(Icons.tag, size: 13.sp, color: AppColorsDark.textTertiary),
              SizedBox(width: 4.w),
              Text(
                order.storeId,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textTertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColorsDark.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColorsDark.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColorsDark.success,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Rider must pick up from this store',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STATUS UPDATE CARD
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildStatusUpdateCard(OrderModel order) {
    final action = _getNextStatusAction(order.status);
    if (action == null) return const SizedBox.shrink();

    final canAssignRider =
        order.riderId == null &&
        (order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.outForDelivery);

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
              Icon(Icons.update, color: AppColorsDark.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Order Actions',
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
            children: [
              Text(
                'Status: ',
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              _statusChip(
                _getStatusText(order.status),
                _getStatusColor(order.status),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward,
                size: 16.sp,
                color: AppColorsDark.textTertiary,
              ),
              SizedBox(width: 8.w),
              _statusChip(_getStatusText(action.next), action.color),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isProcessing
                      ? null
                      : () => _handleUpdateStatus(order, action.next),
              icon:
                  _isProcessing
                      ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColorsDark.white,
                        ),
                      )
                      : Icon(action.icon, size: 20.sp),
              label: Text(
                _isProcessing ? 'Updating...' : action.label,
                style: AppTextStyles.button().copyWith(fontSize: 15.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: action.color,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          if (canAssignRider) ...[
            SizedBox(height: 10.h),
            _riderButton(order, isChange: false),
          ],
          if (order.riderId != null &&
              order.status != OrderStatus.delivered) ...[
            SizedBox(height: 10.h),
            _riderButton(order, isChange: true),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
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

  Widget _riderButton(OrderModel order, {required bool isChange}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed:
            () => showDialog(
              context: context,
              builder: (_) => AssignRiderDialog(order: order),
            ),
        icon: Icon(
          isChange ? Icons.swap_horiz : Icons.delivery_dining,
          size: 20.sp,
        ),
        label: Text(
          isChange ? 'Change Rider' : 'Assign Rider',
          style: AppTextStyles.button().copyWith(
            fontSize: 15.sp,
            color: isChange ? AppColorsDark.warning : AppColorsDark.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          side: BorderSide(
            color: isChange ? AppColorsDark.warning : AppColorsDark.primary,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdateStatus(
    OrderModel order,
    OrderStatus newStatus,
  ) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(ordersProvider.notifier)
          .updateOrderStatus(order.id, newStatus, null, 'admin');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order updated to ${_getStatusText(newStatus).toLowerCase()}',
            ),
            backgroundColor: AppColorsDark.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // ✅ No getOrderById() needed — stream auto-updates _streamOrder
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColorsDark.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PAYMENT INFO — with Verify + Unverify buttons
  // ───────────────────────────────────────────────────────────────────────────

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
          _buildInfoRow('Method', _getPaymentMethodName(order.paymentMethod)),
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

          // ── Proof image + verify / unverify buttons ──────────────────────
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
                Row(
                  children: [
                    // ✅ VERIFY button (shown when pending)
                    if (order.paymentStatus == PaymentStatus.pending)
                      ElevatedButton.icon(
                        onPressed:
                            _isProcessing
                                ? null
                                : () => _handleVerifyPayment(order),
                        icon: Icon(Icons.verified, size: 14.sp),
                        label: const Text('Verify'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsDark.success,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          textStyle: AppTextStyles.labelSmall(),
                        ),
                      ),

                    // ✅ UNVERIFY button (shown when already verified)
                    // Reverts payment to COD so rider knows to collect cash
                    if (order.paymentStatus == PaymentStatus.completed) ...[
                      ElevatedButton.icon(
                        onPressed:
                            _isProcessing
                                ? null
                                : () => _handleUnverifyPayment(order),
                        icon: Icon(Icons.cancel_outlined, size: 14.sp),
                        label: const Text('Unverify'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsDark.error,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          textStyle: AppTextStyles.labelSmall(),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: () => _showFullScreenImage(order.paymentProofUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  order.paymentProofUrl!,
                  width: double.infinity,
                  height: 250.h,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
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
                          ],
                        ),
                      ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
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

  // ✅ Verify payment
  Future<void> _handleVerifyPayment(OrderModel order) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({'paymentStatus': 'completed'});

      if (mounted) {
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
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ✅ NEW: Unverify payment — marks as pending AND switches to COD
  // so the rider knows to collect cash instead of assuming it's paid.
  Future<void> _handleUnverifyPayment(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            icon: Icon(
              Icons.warning_amber_rounded,
              color: AppColorsDark.warning,
              size: 40.sp,
            ),
            title: Text(
              'Unverify Payment?',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'This will mark the payment as unverified and convert the order '
              'to Cash on Delivery. The rider will be asked to collect cash '
              'from the customer.',
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
                  backgroundColor: AppColorsDark.warning,
                ),
                child: const Text('Unverify & Set to COD'),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({
            // ✅ Revert payment status to pending
            'paymentStatus': 'pending',
            // ✅ Switch payment method to COD so rider collects cash
            'paymentMethod': 'cod',
            'updatedAt': FieldValue.serverTimestamp(),
            'statusHistory': FieldValue.arrayUnion([
              {
                'status': order.status.name,
                'timestamp': Timestamp.now(),
                'note': 'Payment unverified by admin — converted to COD',
                'updatedBy': 'admin',
              },
            ]),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment unverified — order converted to COD'),
            backgroundColor: AppColorsDark.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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

  // ───────────────────────────────────────────────────────────────────────────
  // CANCEL ORDER — dialog + handler
  // ───────────────────────────────────────────────────────────────────────────

  bool _canCancelOrder(OrderStatus status) =>
      status == OrderStatus.pending ||
      status == OrderStatus.confirmed ||
      status == OrderStatus.preparing ||
      status == OrderStatus.outForDelivery;

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

  void _showCancelOrderDialog(OrderModel order) {
    // ✅ Clear previous text so the field is fresh
    _cancelReasonController.clear();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
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
              key: _cancelFormKey,
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
                  // ✅ Uses state-field controller — no lifecycle issue
                  TextFormField(
                    controller: _cancelReasonController,
                    maxLines: 3,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please provide a reason';
                      }
                      if (v.trim().length < 10) {
                        return 'At least 10 characters required';
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
                        _buildConsequenceItem('Update status to "Cancelled"'),
                        _buildConsequenceItem('Notify the customer'),
                        if (order.riderId != null)
                          _buildConsequenceItem('Notify the assigned rider'),
                        _buildConsequenceItem('Cannot be undone'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Keep Order',
                  style: TextStyle(color: AppColorsDark.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_cancelFormKey.currentState!.validate()) {
                    // ✅ Capture text before closing
                    final reason = _cancelReasonController.text.trim();
                    Navigator.pop(dialogContext);
                    // ✅ microtask ensures dialog is fully off the tree before setState
                    Future.microtask(
                      () => _handleCancelOrder(order.id, reason),
                    );
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

  Future<void> _handleCancelOrder(String orderId, String reason) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    bool success = false;
    try {
      success = await ref
          .read(ordersProvider.notifier)
          .cancelOrder(orderId, reason);
    } catch (_) {
      success = false;
    }

    // ✅ NEVER call getOrderById() after cancel — it sets OrdersLoading
    // which tears down the scroll view → disposed ScrollController crash.
    // Just pop. The orders list stream updates automatically.

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
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
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel. Please try again.'),
          backgroundColor: AppColorsDark.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REMAINING WIDGETS
  // ───────────────────────────────────────────────────────────────────────────

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity}x ${item.productName}',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
      child: Row(
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
                  DateFormat('MMM d, yyyy • h:mm a').format(order.createdAt),
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
          _buildInfoRow(
            'Phone',
            order.userPhone.isNotEmpty ? order.userPhone : 'Not provided',
          ),
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
            '${order.deliveryAddress.addressLine1}, '
            '${order.deliveryAddress.area}, ${order.deliveryAddress.city}',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
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

  Widget _buildCancellationInfo(OrderModel order) {
    if (order.status != OrderStatus.cancelled ||
        order.cancellationReason == null)
      return const SizedBox.shrink();
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
          Divider(color: AppColorsDark.error),
          SizedBox(height: 12.h),
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

  Widget _buildRiderRefusalInfo(OrderModel order) {
    if (order.riderRefusalReason == null) return const SizedBox.shrink();
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
          Divider(color: AppColorsDark.warning),
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
    final c = _getStatusColor(status);
    return LinearGradient(
      colors: [c, c.withOpacity(0.7)],
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
