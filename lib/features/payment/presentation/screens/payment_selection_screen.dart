// lib/features/payment/presentation/screens/payment_selection_screen.dart

import 'package:abw_app/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../../orders/domain/entities/order_entity.dart';
import 'cod_confirmation_screen.dart';
import 'jazzcash_payment_screen.dart';
import 'easypaisa_payment_screen.dart';
import 'bank_transfer_payment_screen.dart';

class PaymentSelectionScreen extends ConsumerStatefulWidget {
  const PaymentSelectionScreen({super.key});

  @override
  ConsumerState<PaymentSelectionScreen> createState() =>
      _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState
    extends ConsumerState<PaymentSelectionScreen> {
  PaymentMethod? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);

    if (checkoutState is! CheckoutLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(child: Text('Something went wrong')),
      );
    }

    final checkout = checkoutState.checkout;

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Payment Method',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Amount Display
                  _buildTotalAmountCard(checkout.total),
                  SizedBox(height: 24.h),

                  // Payment Methods Section
                  Text(
                    'Select Payment Method',
                    style: AppTextStyles.titleMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Cash on Delivery
                  _buildPaymentMethodTile(
                    method: PaymentMethod.cod,
                    icon: Icons.money,
                    title: 'Cash on Delivery',
                    subtitle: 'Pay when you receive your order',
                    color: AppColorsDark.success,
                  ),

                  SizedBox(height: 12.h),

                  // JazzCash
                  _buildPaymentMethodTile(
                    method: PaymentMethod.jazzcash,
                    icon: Icons.account_balance_wallet,
                    title: 'JazzCash',
                    subtitle: 'Pay via JazzCash mobile wallet',
                    color: const Color(0xFFFF6B00),
                  ),

                  SizedBox(height: 12.h),

                  // EasyPaisa
                  _buildPaymentMethodTile(
                    method: PaymentMethod.easypaisa,
                    icon: Icons.payment,
                    title: 'EasyPaisa',
                    subtitle: 'Pay via EasyPaisa mobile wallet',
                    color: const Color(0xFF00A651),
                  ),

                  SizedBox(height: 12.h),

                  // Bank Transfer
                  _buildPaymentMethodTile(
                    method: PaymentMethod.bankTransfer,
                    icon: Icons.account_balance,
                    title: 'Bank Transfer',
                    subtitle: 'Transfer to our bank account',
                    color: AppColorsDark.info,
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

  Widget _buildTotalAmountCard(double total) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Amount',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'PKR ${total.toInt()}',
                style: AppTextStyles.headlineMedium().copyWith(
                  color: AppColorsDark.white,
                  fontWeight: FontWeight.bold,
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
              size: 32.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? color : AppColorsDark.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Radio
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColorsDark.border,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child:
                  isSelected
                      ? Icon(
                        Icons.check,
                        color: AppColorsDark.white,
                        size: 16.sp,
                      )
                      : null,
            ),
          ],
        ),
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
          onPressed: _selectedMethod != null ? _proceedWithPayment : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 56.h),
            disabledBackgroundColor: AppColorsDark.surfaceVariant,
          ),
          child: Text(
            'Continue',
            style: AppTextStyles.button().copyWith(fontSize: 16.sp),
          ),
        ),
      ),
    );
  }

  void _proceedWithPayment() {
    if (_selectedMethod == null) return;

    switch (_selectedMethod!) {
      case PaymentMethod.cod:
        // ✅ USE GoRouter
        context.push('/customer/payment/cod');
        break;
      case PaymentMethod.jazzcash:
        context.push('/customer/payment/jazzcash');
        break;
      case PaymentMethod.easypaisa:
        context.push('/customer/payment/easypaisa');
        break;
      case PaymentMethod.bankTransfer:
        context.push('/customer/payment/bank');
        break;
    }
  }
}
