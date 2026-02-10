// lib/features/payment/presentation/screens/order_confirmation_screen.dart

import 'package:abw_app/core/routes/app_router.dart';
import 'package:abw_app/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:abw_app/features/orders/domain/entities/order_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/data/models/order_model.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Load order details
    ref.read(ordersProvider.notifier).getOrderById(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return WillPopScope(
      onWillPop: () async {
        // Navigate to home instead of going back
        context.goToCustomerHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColorsDark.background,
        appBar: AppBar(
          title: Text(
            'Order Confirmation',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          backgroundColor: AppColorsDark.surface,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.goToCustomerHome(),
          ),
        ),
        body:
            ordersState is OrdersLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColorsDark.primary,
                  ),
                )
                : ordersState is OrderSingleLoaded
                ? _buildConfirmationContent(ordersState.order)
                : const Center(child: Text('Unable to load order details')),
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

                // Success Animation
                Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColorsDark.success.withOpacity(0.15),
                        AppColorsDark.success.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 120.sp,
                    color: AppColorsDark.success,
                  ),
                ),

                SizedBox(height: 32.h),

                // Success Message
                Text(
                  'Order Placed Successfully!',
                  style: AppTextStyles.headlineMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12.h),

                Text(
                  'Thank you for your order',
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
                  child: Column(
                    children: [
                      Text(
                        'Order ID',
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        order.id,
                        style: AppTextStyles.headlineSmall().copyWith(
                          color: AppColorsDark.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Order Summary
                Container(
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
                        style: AppTextStyles.titleMedium().copyWith(
                          color: AppColorsDark.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _buildSummaryRow('Items', '${order.items.length}'),
                      _buildSummaryRow(
                        'Total Amount',
                        'PKR ${order.total.toInt()}',
                      ),
                      _buildSummaryRow(
                        'Payment Method',
                        _getPaymentMethodName(order.paymentMethod),
                      ),
                      _buildSummaryRow(
                        'Delivery Time',
                        ref
                            .read(checkoutProvider.notifier)
                            .getDeliveryTimeRange(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Next Steps
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColorsDark.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColorsDark.info.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColorsDark.info,
                            size: 20.sp,
                          ),
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
                      _buildNextStep('1', 'We are reviewing your order'),
                      _buildNextStep('2', 'Restaurant will prepare your food'),
                      _buildNextStep('3', 'Rider will pick up and deliver'),
                      _buildNextStep('4', 'You will receive your order!'),
                    ],
                  ),
                ),

                if (order.paymentMethod != PaymentMethod.cod) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColorsDark.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColorsDark.warning.withOpacity(0.3),
                      ),
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
                            'Your payment is under verification. We will confirm your order once payment is verified.',
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
          ),
        ),

        // Bottom Buttons
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
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
      ),
    );
  }

  Widget _buildNextStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                text,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.info,
                ),
              ),
            ),
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
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to orders screen (Day 2 Part 2)
                  context.goToActiveOrders();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56.h),
                ),
                child: const Text('Track Order'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.goToCustomerHome(),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56.h),
                ),
                child: const Text('Continue Shopping'),
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
