// lib/features/payment/presentation/screens/order_confirmation_screen.dart
// FULL REPLACEMENT:

import 'package:abw_app/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/domain/entities/order_entity.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({required this.orderId, super.key});

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ Load order after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).getOrderById(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) context.goToCustomerHome();
      },
      child: Scaffold(
        backgroundColor: AppColorsDark.background,
        appBar: AppBar(
          title: Text(
            'Order Confirmed',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          backgroundColor: AppColorsDark.surface,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            color: AppColorsDark.textPrimary,
            onPressed: () => context.goToCustomerHome(),
          ),
        ),
        body: switch (ordersState) {
          OrdersLoading() => const Center(
            child: CircularProgressIndicator(color: AppColorsDark.primary),
          ),
          OrderSingleLoaded(:final order) => _buildConfirmationContent(order),
          OrdersError(:final message) => _buildErrorState(message),
          _ => const Center(
            child: CircularProgressIndicator(color: AppColorsDark.primary),
          ),
        },
      ),
    );
  }

  Widget _buildConfirmationContent(OrderModel order) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),

                // ✅ Success Icon (no Lottie dependency needed)
                Container(
                  width: 160.w,
                  height: 160.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColorsDark.success.withOpacity(0.2),
                        AppColorsDark.success.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColorsDark.success.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 100.sp,
                    color: AppColorsDark.success,
                  ),
                ),

                SizedBox(height: 24.h),

                Text(
                  'Order Placed! 🎉',
                  style: AppTextStyles.headlineMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                Text(
                  'Your order has been received and\nis being processed.',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32.h),

                // Order ID Card
                Container(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order ID',
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.white.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '#${order.id.substring(order.id.length - 8)}',
                            style: AppTextStyles.headlineSmall().copyWith(
                              color: AppColorsDark.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
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
                          size: 28.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Order Summary Card
                _buildSummaryCard(order),

                SizedBox(height: 20.h),

                // What happens next
                _buildNextStepsCard(order),

                // Payment pending notice
                if (order.paymentMethod != PaymentMethod.cod) ...[
                  SizedBox(height: 16.h),
                  _buildPaymentPendingNotice(),
                ],
              ],
            ),
          ),
        ),

        // Bottom Buttons
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildSummaryCard(OrderModel order) {
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
            'Order Summary',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _summaryRow('Store', order.storeName),
          SizedBox(height: 8.h),
          _summaryRow(
            'Items',
            '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
          ),
          SizedBox(height: 8.h),
          _summaryRow('Payment', _getPaymentMethodName(order.paymentMethod)),
          SizedBox(height: 8.h),
          const Divider(color: AppColorsDark.border),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'PKR ${order.total.toInt()}',
                style: AppTextStyles.titleMedium().copyWith(
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

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepsCard(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.info.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColorsDark.info, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'What happens next?',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _nextStep('1', 'We review your order'),
          _nextStep('2', 'Restaurant prepares your food'),
          _nextStep('3', 'Rider picks up and delivers'),
          _nextStep('4', 'Enjoy your meal! 🍽️'),
        ],
      ),
    );
  }

  Widget _nextStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: const BoxDecoration(
              color: AppColorsDark.info,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.labelSmall().copyWith(
                  color: AppColorsDark.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPendingNotice() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.pending_actions,
            color: AppColorsDark.warning,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Your payment is under verification. We will confirm your order once the payment is verified by our team.',
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.warning,
              ),
            ),
          ),
        ],
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
            'Could not load order details',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Order ID: #${widget.orderId.substring(widget.orderId.length - 8)}',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.goToCustomerHome(),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.goToActiveOrders(),
                icon: Icon(Icons.local_shipping_outlined, size: 18.sp),
                label: const Text('Track Order'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.goToCustomerHome(),
                icon: Icon(Icons.home_outlined, size: 18.sp),
                label: const Text('Home'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
