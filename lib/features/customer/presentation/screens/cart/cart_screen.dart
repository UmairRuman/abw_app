// lib/features/customer/presentation/screens/cart/cart_screen.dart

import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:abw_app/features/cart/data/models/cart_item_model.dart';
import 'package:abw_app/features/products/presentation/providers/products_provider.dart';
import 'package:abw_app/features/stores/presentation/providers/stores_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as ref;
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../cart/presentation/providers/cart_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.read(authProvider);

    if (authState is! Authenticated) {
      return Scaffold(
        body: Center(child: Text('Please login to view cart')),
      );
    }

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'My Cart',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        actions: [
          if (cartState is CartLoaded && cartState.cart.isNotEmpty)
            TextButton(
              onPressed: () {
                _showClearCartDialog(context, ref, authState.user.id);
              },
              child: Text('Clear All'),
            ),
        ],
      ),
      body: cartState is CartLoading
          ? Center(child: CircularProgressIndicator(color: AppColorsDark.primary))
          : cartState is CartLoaded
              ? cartState.cart.isEmpty
                  ? _buildEmptyCart(context)
                  : _buildCartContent(context, ref, cartState, authState.user.id)
              : Center(child: Text('Error loading cart')),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120.sp,
            color: AppColorsDark.textTertiary,
          ),
          SizedBox(height: 24.h),
          Text(
            'Your cart is empty',
            style: AppTextStyles.headlineMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Add items to get started',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: () {
             
              context.go('/customer/home');
            },
            child: const Text('Browse Stores'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
    BuildContext context,
    WidgetRef ref,
    CartLoaded state,
    String userId,
  ) {
    return Column(
      children: [
        // Store Info Banner
        Container(
          padding: EdgeInsets.all(16.w),
          color: AppColorsDark.surface,
          child: Row(
            children: [
              Icon(Icons.store, color: AppColorsDark.primary),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.cart.storeName!,
                      style: AppTextStyles.titleSmall().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${state.cart.totalItems} items',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Cart Items
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: state.cart.items.length,
            itemBuilder: (context, index) {
              final item = state.cart.items[index];
              return _buildCartItem(context, ref, item, userId);
            },
          ),
        ),

        // Bottom Summary
        _buildBottomSummary(context, ref, state),
      ],
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    CartItemModel item,
    String userId,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              width: 70.w,
              height: 70.w,
              color: AppColorsDark.surfaceContainer,
              child: Icon(Icons.fastfood, size: 30.sp),
            ),
          ),

          SizedBox(width: 12.w),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  item.unit,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      'PKR ${item.total.toInt()}',
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.discountedPrice < item.price) ...[
                      SizedBox(width: 8.w),
                      Text(
                        'PKR ${item.price.toInt()}',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: AppColorsDark.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                IconButton(
                  icon: Icon(Icons.add, size: 18.sp),
                  color: AppColorsDark.primary,
                  onPressed: () {
                    ref.read(cartProvider.notifier).incrementQuantity(
                          userId,
                          item.productId,
                        );
                  },
                  constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    '${item.quantity}',
                    style: AppTextStyles.titleSmall().copyWith(
                      color: AppColorsDark.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    item.quantity > 1 ? Icons.remove : Icons.delete_outline,
                    size: 18.sp,
                  ),
                  color: item.quantity > 1
                      ? AppColorsDark.primary
                      : AppColorsDark.error,
                  onPressed: () {
                    if (item.quantity > 1) {
                      ref.read(cartProvider.notifier).decrementQuantity(
                            userId,
                            item.productId,
                          );
                    } else {
                      _showRemoveItemDialog(context, ref, userId, item);
                    }
                  },
                  constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(
    BuildContext context,
    WidgetRef ref,
    CartLoaded state,
  ) {
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
        child: Column(
          children: [
            _buildSummaryRow('Subtotal', state.cart.subtotal),
            _buildSummaryRow('Delivery Fee', state.cart.deliveryFee),
            if (state.cart.discount > 0)
              _buildSummaryRow('Discount', -state.cart.discount,
                  color: AppColorsDark.success),
            Divider(height: 24.h),
            _buildSummaryRow('Total', state.cart.total, isTotal: true),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to checkout
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checkout coming in Milestone 2'),
                    backgroundColor: AppColorsDark.info,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56.h),
              ),
              child: Text('Proceed to Checkout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isTotal = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isTotal
                    ? AppTextStyles.titleMedium()
                    : AppTextStyles.bodyMedium())
                .copyWith(
              color: color ?? AppColorsDark.textPrimary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'PKR ${amount.toInt()}',
            style: (isTotal
                    ? AppTextStyles.titleMedium()
                    : AppTextStyles.bodyMedium())
                .copyWith(
              color: color ?? AppColorsDark.textPrimary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    CartItemModel item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDark.surface,
        title: Text('Remove Item?'),
        content: Text('Remove ${item.productName} from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).removeItem(
                    userId,
                    item.productId,
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDark.error,
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDark.surface,
        title: Text('Clear Cart?'),
        content: Text('Remove all items from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart(userId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDark.error,
            ),
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
}