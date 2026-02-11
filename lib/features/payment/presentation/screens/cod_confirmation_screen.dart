// lib/features/payment/presentation/screens/cod_confirmation_screen.dart

import 'package:abw_app/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../orders/domain/entities/order_entity.dart';

class CodConfirmationScreen extends ConsumerStatefulWidget {
  const CodConfirmationScreen({super.key});

  @override
  ConsumerState<CodConfirmationScreen> createState() =>
      _CodConfirmationScreenState();
}

class _CodConfirmationScreenState extends ConsumerState<CodConfirmationScreen> {
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);

    if (checkoutState is! CheckoutLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cash on Delivery')),
        body: const Center(child: Text('Something went wrong')),
      );
    }

    final checkout = checkoutState.checkout;

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Cash on Delivery',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  SizedBox(height: 20.h),

                  // COD Icon
                  Container(
                    padding: EdgeInsets.all(24.w),
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
                      Icons.money,
                      size: 80.sp,
                      color: AppColorsDark.success,
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Title
                  Text(
                    'Cash on Delivery',
                    style: AppTextStyles.headlineMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Description
                  Text(
                    'You will pay in cash when your order is delivered to your doorstep',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 32.h),

                  // Amount to Pay
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColorsDark.cardBackground,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColorsDark.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount to Pay',
                          style: AppTextStyles.titleMedium().copyWith(
                            color: AppColorsDark.textPrimary,
                          ),
                        ),
                        Text(
                          'PKR ${checkout.total.toInt()}',
                          style: AppTextStyles.headlineSmall().copyWith(
                            color: AppColorsDark.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Instructions
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColorsDark.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColorsDark.info.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColorsDark.info,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Notes:',
                                style: AppTextStyles.titleSmall().copyWith(
                                  color: AppColorsDark.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              _buildNote('Please keep exact change ready'),
                              _buildNote(
                                'Payment will be collected by the rider',
                              ),
                              _buildNote(
                                'You can cancel this order anytime before confirmation',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Button
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.info,
            ),
          ),
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

  Widget _buildBottomBar() {
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
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 56.h),
            backgroundColor: AppColorsDark.success,
          ),
          child:
              _isPlacingOrder
                  ? SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColorsDark.white,
                    ),
                  )
                  : Text(
                    'Place Order',
                    style: AppTextStyles.button().copyWith(fontSize: 16.sp),
                  ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);

    try {
      final authState = ref.read(authProvider);
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final checkoutState = ref.read(checkoutProvider);
      if (checkoutState is! CheckoutLoaded) {
        throw Exception('Checkout data not available');
      }

      // Place order with COD
      final orderId = await ref
          .read(ordersProvider.notifier)
          .placeOrder(
            userId: authState.user.id,
            userName: authState.user.name,
            userPhone: authState.user.phone,
            paymentMethod: PaymentMethod.cod,
            paymentProofUrl: null, // No proof needed for COD
          );

      if (orderId != null && mounted) {
        // ✅ Reset AFTER navigation to avoid the crash
        context.goToOrderConfirmation(orderId);
        // ✅ Reset AFTER navigating
        Future.delayed(const Duration(milliseconds: 100), () {
          ref.read(checkoutProvider.notifier).reset();
        });
      } else {
        throw Exception('Failed to place order');
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
        setState(() => _isPlacingOrder = false);
      }
    }
  }
}
