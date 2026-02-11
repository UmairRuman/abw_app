// lib/features/payment/presentation/screens/jazzcash_payment_screen.dart

import 'dart:io';
import 'package:abw_app/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../core/presentation/providers/image_upload_provider.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../orders/domain/entities/order_entity.dart';
import 'order_confirmation_screen.dart';

class JazzcashPaymentScreen extends ConsumerStatefulWidget {
  const JazzcashPaymentScreen({super.key});

  @override
  ConsumerState<JazzcashPaymentScreen> createState() =>
      _JazzcashPaymentScreenState();
}

class _JazzcashPaymentScreenState extends ConsumerState<JazzcashPaymentScreen> {
  File? _paymentScreenshot;
  bool _isUploading = false;
  bool _isPlacingOrder = false;

  final String _jazzcashNumber = '03072740036';

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);

    if (checkoutState is! CheckoutLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('JazzCash Payment')),
        body: const Center(child: Text('Something went wrong')),
      );
    }

    final checkout = checkoutState.checkout;

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'JazzCash Payment',
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
                  // JazzCash Logo/Icon
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF6B00).withOpacity(0.15),
                            const Color(0xFFFF6B00).withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 80.sp,
                        color: const Color(0xFFFF6B00),
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Amount to Pay
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF6B00).withOpacity(0.15),
                          const Color(0xFFFF6B00).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(0xFFFF6B00).withOpacity(0.3),
                      ),
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
                            color: const Color(0xFFFF6B00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Payment Instructions
                  Text(
                    'Payment Instructions',
                    style: AppTextStyles.titleMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildInstructionCard(
                    step: '1',
                    title: 'Send Money via JazzCash',
                    description: 'Open your JazzCash app and send money to:',
                  ),

                  SizedBox(height: 12.h),

                  // JazzCash Number
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFFF6B00).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JazzCash Number',
                              style: AppTextStyles.bodySmall().copyWith(
                                color: AppColorsDark.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _jazzcashNumber,
                              style: AppTextStyles.headlineSmall().copyWith(
                                color: const Color(0xFFFF6B00),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _jazzcashNumber),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Number copied!'),
                                backgroundColor: AppColorsDark.success,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  _buildInstructionCard(
                    step: '2',
                    title: 'Take Screenshot',
                    description:
                        'After successful payment, take a screenshot of the confirmation.',
                  ),

                  SizedBox(height: 12.h),

                  _buildInstructionCard(
                    step: '3',
                    title: 'Upload Screenshot',
                    description:
                        'Upload the payment screenshot below to complete your order.',
                  ),

                  SizedBox(height: 24.h),

                  // Upload Screenshot Section
                  _buildUploadSection(),

                  SizedBox(height: 24.h),

                  // Warning Notice
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColorsDark.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColorsDark.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColorsDark.error,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Important: Your order will NOT be processed until you upload a valid payment screenshot. Orders without payment proof will be automatically cancelled.',
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.error,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildInstructionCard({
    required String step,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B00),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: AppTextStyles.titleSmall().copyWith(
                color: AppColorsDark.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
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
                description,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
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
            'Payment Screenshot',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),

          if (_paymentScreenshot == null)
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                height: 200.h,
                decoration: BoxDecoration(
                  color: AppColorsDark.surfaceVariant,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColorsDark.border,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 64.sp,
                        color: AppColorsDark.textTertiary,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Tap to upload screenshot',
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'JPG, PNG (Max 5MB)',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.file(
                    _paymentScreenshot!,
                    width: double.infinity,
                    height: 300.h,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Row(
                    children: [
                      // Change Image
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: const BoxDecoration(
                            color: AppColorsDark.info,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit,
                            color: AppColorsDark.white,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Remove Image
                      InkWell(
                        onTap: () {
                          setState(() => _paymentScreenshot = null);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: const BoxDecoration(
                            color: AppColorsDark.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            color: AppColorsDark.white,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final canPlaceOrder = _paymentScreenshot != null && !_isPlacingOrder;

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
          onPressed: canPlaceOrder ? _placeOrder : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 56.h),
            backgroundColor: const Color(0xFFFF6B00),
            disabledBackgroundColor: AppColorsDark.surfaceVariant,
          ),
          child:
              _isPlacingOrder || _isUploading
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24.h,
                        width: 24.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColorsDark.white,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        _isUploading ? 'Uploading...' : 'Placing Order...',
                        style: AppTextStyles.button().copyWith(fontSize: 16.sp),
                      ),
                    ],
                  )
                  : Text(
                    _paymentScreenshot == null
                        ? 'Upload Screenshot First'
                        : 'Confirm & Place Order',
                    style: AppTextStyles.button().copyWith(fontSize: 16.sp),
                  ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _paymentScreenshot = File(pickedFile.path);
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_paymentScreenshot == null) return;

    setState(() => _isUploading = true);

    try {
      // Upload screenshot to Cloudinary
      final imageUrls = await ref
          .read(imageUploadProvider.notifier)
          .uploadPaymentProof([_paymentScreenshot!]);

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload payment screenshot');
      }

      final paymentProofUrl = imageUrls.first;

      setState(() {
        _isUploading = false;
        _isPlacingOrder = true;
      });

      // Place order
      final authState = ref.read(authProvider);
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final orderId = await ref
          .read(ordersProvider.notifier)
          .placeOrder(
            userId: authState.user.id,
            userName: authState.user.name,
            userPhone: authState.user.phone,
            paymentMethod: PaymentMethod.jazzcash,
            paymentProofUrl: paymentProofUrl,
          );

      if (orderId != null && mounted) {
        context.goToOrderConfirmation(orderId);
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
        setState(() {
          _isUploading = false;
          _isPlacingOrder = false;
        });
      }
    }
  }
}
