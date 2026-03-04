// lib/features/orders/presentation/screens/customer/order_details_screen.dart
// UPDATED: Show rider info and helpline instead of customer info

import 'package:abw_app/features/orders/data/models/order_model.dart';
import 'package:abw_app/features/orders/domain/entities/order_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ ADD THIS for phone calls
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/order_status_timeline.dart';
import '../../../../cart/data/models/cart_item_model.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsScreen({required this.orderId, super.key});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _isCancelling = false;
  String? _helplineNumber; // ✅ NEW: Store helpline number

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).getOrderById(widget.orderId);
      _loadHelplineNumber(); // ✅ NEW: Load helpline
    });
  }

  // ✅ NEW: Load helpline number from settings
  Future<void> _loadHelplineNumber() async {
    try {
      final settingsDoc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('general')
              .get();

      if (settingsDoc.exists && mounted) {
        setState(() {
          _helplineNumber = settingsDoc.data()?['helplineNumber'] as String?;
        });
      }
    } catch (e) {
      print('Error loading helpline: $e');
    }
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
              : ordersState is OrdersError
              ? _buildErrorState(ordersState.message)
              : const Center(child: Text('Unable to load order details')),
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    final canCancel = order.status == OrderStatus.pending;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID Card
                _buildOrderIdCard(order),
                SizedBox(height: 20.h),

                // Status Timeline
                OrderStatusTimeline(
                  currentStatus: order.status,
                  statusHistory: order.statusHistory,
                ),
                SizedBox(height: 20.h),

                // ✅ NEW: Rider Info (replaces customer info)
                _buildRiderAndHelplineInfo(order),
                SizedBox(height: 20.h),

                // Delivery Address (keep this)
                _buildDeliveryAddress(order),
                SizedBox(height: 20.h),

                // Order Items
                _buildOrderItems(order),
                SizedBox(height: 20.h),

                // Payment Info
                _buildPaymentInfo(order),
                SizedBox(height: 20.h),

                // Price Breakdown
                _buildPriceBreakdown(order),
                SizedBox(height: 20.h),

                // Special Instructions
                if (order.specialInstructions != null &&
                    order.specialInstructions!.isNotEmpty)
                  _buildSpecialInstructions(order.specialInstructions!),
              ],
            ),
          ),
        ),

        if (canCancel) _buildCancelButton(order),
      ],
    );
  }

  // ✅ NEW: Show Rider Info + Helpline (instead of customer info)
  Widget _buildRiderAndHelplineInfo(OrderModel order) {
    final hasRider = order.riderId != null;

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
                Icons.support_agent,
                color: AppColorsDark.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Contact Information',
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

          // ✅ Rider Info (if assigned)
          if (hasRider) ...[
            _buildContactItem(
              icon: Icons.delivery_dining,
              title: 'Your Delivery Rider',
              name: order.riderName ?? 'Unknown',
              phone: order.riderPhone,
              color: AppColorsDark.success,
            ),
            SizedBox(height: 12.h),
            const Divider(color: AppColorsDark.border),
            SizedBox(height: 12.h),
          ],

          // ✅ Helpline Number
          _buildContactItem(
            icon: Icons.headset_mic,
            title: 'Customer Support Helpline',
            name: 'Need Help?',
            phone: _helplineNumber ?? '1234', // Default if not set
            color: AppColorsDark.info,
          ),

          // Message if no rider assigned yet
          if (!hasRider) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColorsDark.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColorsDark.warning,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Delivery rider will be assigned soon',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ NEW: Build contact item with call button
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String name,
    String? phone,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                name,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (phone != null && phone.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      phone,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: () => _makePhoneCall(phone),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14.sp,
                              color: AppColorsDark.white,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Call',
                              style: AppTextStyles.labelSmall().copyWith(
                                color: AppColorsDark.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ✅ NEW: Make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not make call'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
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
          if (order.estimatedDeliveryTime != null) ...[
            SizedBox(height: 12.h),
            const Divider(color: AppColorsDark.border),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppColorsDark.success,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Estimated Delivery: ${DateFormat('h:mm a').format(order.estimatedDeliveryTime!)}',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ... rest of methods (same as before)
  // Keep all the existing methods: _buildOrderIdCard, _buildOrderItems,
  // _buildPaymentInfo, _buildPriceBreakdown, etc.

  Widget _buildOrderIdCard(OrderModel order) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '#${order.id.substring(order.id.length - 8)}',
                  style: AppTextStyles.headlineSmall().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 8.h),
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
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColorsDark.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.receipt_long,
              color: AppColorsDark.white,
              size: 32.sp,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Items',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColorsDark.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${order.items.length} items',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...order.items.map((item) => _buildOrderItem(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItemModel item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child:
                item.productImage.isNotEmpty
                    ? Image.network(
                      item.productImage,
                      width: 60.w,
                      height: 60.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    )
                    : _buildImagePlaceholder(),
          ),
          SizedBox(width: 12.w),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  'Qty: ${item.quantity}',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'PKR ${item.total.toInt()}',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 60.w,
      height: 60.w,
      color: AppColorsDark.surfaceContainer,
      child: Icon(
        Icons.fastfood,
        size: 24.sp,
        color: AppColorsDark.textTertiary,
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
          Row(
            children: [
              Icon(Icons.payment, color: AppColorsDark.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Payment Information',
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
                'Payment Method',
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

  Widget _buildCancelButton(OrderModel order) {
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
          onPressed: _isCancelling ? null : () => _showCancelDialog(order),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 56.h),
            backgroundColor: AppColorsDark.error,
          ),
          child:
              _isCancelling
                  ? SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColorsDark.white,
                    ),
                  )
                  : Text(
                    'Cancel Order',
                    style: AppTextStyles.button().copyWith(fontSize: 16.sp),
                  ),
        ),
      ),
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
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(OrderModel order) {
    showDialog(
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
              'Are you sure you want to cancel this order? This action cannot be undone.',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No, Keep Order'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelOrder(order.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                ),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    setState(() => _isCancelling = true);

    try {
      final success = await ref
          .read(ordersProvider.notifier)
          .cancelOrder(orderId, 'Cancelled by customer');

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: AppColorsDark.success,
          ),
        );
        await ref.read(ordersProvider.notifier).getOrderById(orderId);
      } else {
        throw Exception('Failed to cancel order');
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
      if (mounted) {
        setState(() => _isCancelling = false);
      }
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
