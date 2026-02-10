// lib/features/checkout/presentation/screens/checkout_screen.dart

import 'package:abw_app/core/routes/app_router.dart';
import 'package:abw_app/features/customer/presentation/screens/addresses/addresses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/checkout_provider.dart';
import '../../../addresses/data/models/address_model.dart';

import '../../../cart/data/models/cart_item_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _loadCheckout();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // final checkoutState = ref.read(checkoutProvider);
    // if (checkoutState is CheckoutInitial) {
    //   final authState = ref.read(authProvider);

    //   if (authState is Authenticated) {
    //     ref.read(checkoutProvider.notifier).prepareCheckout(authState.user.id);
    //   }
    // }
  }

  // Future<void> _loadCheckout() async {
  //   final authState = ref.read(authProvider);
  //   if (authState is Authenticated) {
  //     await ref
  //         .read(checkoutProvider.notifier)
  //         .prepareCheckout(authState.user.id);
  //   }
  // }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body:
          checkoutState is CheckoutLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              )
              : checkoutState is CheckoutError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.sp,
                      color: AppColorsDark.error,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      checkoutState.message,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
              : checkoutState is CheckoutLoaded
              ? _buildCheckoutContent(checkoutState)
              : const Center(child: Text('Please try again')),
    );
  }

  Widget _buildCheckoutContent(CheckoutLoaded state) {
    final checkout = state.checkout;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Address Section
                _buildDeliveryAddressSection(
                  checkout.deliveryAddress as AddressModel,
                ),
                SizedBox(height: 20.h),

                // Estimated Delivery Time
                _buildDeliveryTimeSection(),
                SizedBox(height: 20.h),

                // Order Items
                _buildOrderItemsSection(checkout.items as List<CartItemModel>),
                SizedBox(height: 20.h),

                // Special Instructions
                _buildSpecialInstructionsSection(),
                SizedBox(height: 20.h),

                // Price Breakdown
                _buildPriceBreakdown(checkout),
              ],
            ),
          ),
        ),

        // Bottom Bar - Proceed to Payment
        _buildBottomBar(checkout.total),
      ],
    );
  }

  Widget _buildDeliveryAddressSection(AddressModel address) {
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
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColorsDark.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColorsDark.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Delivery Address',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: _showAddressSelection,
                child: Text(
                  'Change',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsDark.border),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.person,
                size: 16.sp,
                color: AppColorsDark.textSecondary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${address.name} • ${address.phone}',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.home, size: 16.sp, color: AppColorsDark.textSecondary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${address.addressLine1}, ${address.area}, ${address.city}',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeSection() {
    final deliveryTimeRange =
        ref.read(checkoutProvider.notifier).getDeliveryTimeRange();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsDark.success.withOpacity(0.15),
            AppColorsDark.success.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColorsDark.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.access_time,
              color: AppColorsDark.success,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Delivery',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  deliveryTimeRange,
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.info_outline, size: 18.sp, color: AppColorsDark.success),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(List<CartItemModel> items) {
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
            'Order Items (${items.length})',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          ...items.map((item) => _buildOrderItem(item)),
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
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child:
                item.productImage.isNotEmpty
                    ? Image.network(
                      item.productImage,
                      width: 50.w,
                      height: 50.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    )
                    : _buildImagePlaceholder(),
          ),
          SizedBox(width: 12.w),

          // Details
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

          // Price
          Text(
            'PKR ${(item.price * item.quantity).toInt()}',
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
      width: 50.w,
      height: 50.w,
      color: AppColorsDark.surfaceContainer,
      child: Icon(
        Icons.fastfood,
        size: 24.sp,
        color: AppColorsDark.textTertiary,
      ),
    );
  }

  Widget _buildSpecialInstructionsSection() {
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
                Icons.note_alt_outlined,
                size: 20.sp,
                color: AppColorsDark.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                'Special Instructions (Optional)',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _instructionsController,
            maxLines: 3,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., No onions, extra spicy, ring the bell...',
              hintStyle: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textTertiary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColorsDark.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColorsDark.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppColorsDark.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              ref
                  .read(checkoutProvider.notifier)
                  .updateSpecialInstructions(
                    value.trim().isEmpty ? null : value.trim(),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(checkout) {
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
          _buildPriceRow('Subtotal', (checkout.subtotal as double)),
          SizedBox(height: 8.h),
          _buildPriceRow('Delivery Fee', (checkout.deliveryFee as double)),
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
                'PKR ${checkout.total.toInt()}',
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

  Widget _buildPriceRow(String label, double amount) {
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
          'PKR ${amount.toInt()}',
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double total) {
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
          onPressed: _proceedToPayment,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 56.h),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Proceed to Payment',
                style: AppTextStyles.button().copyWith(fontSize: 16.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                '• PKR ${total.toInt()}',
                style: AppTextStyles.button().copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressesScreen()),
    );

    if (result != null && result is AddressModel) {
      ref.read(checkoutProvider.notifier).updateDeliveryAddress(result);
    }
  }

  void _proceedToPayment() {
    context.goToPaymentSelection();
  }
}
