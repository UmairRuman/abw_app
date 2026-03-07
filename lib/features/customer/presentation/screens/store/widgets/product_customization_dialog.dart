// lib/features/customer/presentation/screens/store/widgets/product_customization_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../products/data/models/product_model.dart';
import '../../../../../products/domain/entities/product_variant.dart';

class ProductCustomizationDialog extends ConsumerStatefulWidget {
  final ProductModel product;

  final Function(
    ProductModel product,
    ProductVariant? selectedVariant,
    List<ProductAddon> selectedAddons,
    String? specialInstructions,
  )
  onAddToCart;

  const ProductCustomizationDialog({
    required this.product,
    required this.onAddToCart,
    super.key,
  });

  @override
  ConsumerState<ProductCustomizationDialog> createState() =>
      _ProductCustomizationDialogState();
}

class _ProductCustomizationDialogState
    extends ConsumerState<ProductCustomizationDialog> {
  ProductVariant? _selectedVariant;
  final List<ProductAddon> _selectedAddons = [];
  final TextEditingController _instructionsController = TextEditingController();
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product.hasVariants && widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  // ✅ FIXED: Variant price is the FULL standalone price for that size.
  // It does NOT add on top of the base product price.
  // Addons remain additional on top of whichever price applies.
  double _calculateTotal() {
    final double basePrice =
        _selectedVariant != null
            ? _selectedVariant!
                .price // ← variant price = full item price
            : widget.product.discountedPrice; // ← fallback if no variants

    final double addonsExtra = _selectedAddons.fold(
      0.0,
      (sum, addon) => sum + addon.price,
    );

    return (basePrice + addonsExtra) * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColorsDark.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColorsDark.textTertiary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          if (widget.product.images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: Image.network(
                widget.product.images.first,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: AppTextStyles.headlineSmall().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // ✅ Only show base price when there are NO variants.
                  // When variants exist, price is determined by size selection below.
                  if (!widget.product.hasVariants ||
                      widget.product.variants.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        'PKR ${widget.product.discountedPrice.toInt()}',
                        style: AppTextStyles.titleMedium().copyWith(
                          color: AppColorsDark.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  Text(
                    widget.product.description,
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),

                  if (widget.product.hasVariants &&
                      widget.product.variants.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _buildSectionTitle('Select Size'),
                    SizedBox(height: 12.h),
                    _buildVariantSelector(),
                  ],

                  if (widget.product.addons.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _buildSectionTitle('Add Extras'),
                    SizedBox(height: 12.h),
                    _buildAddonsSelector(),
                  ],

                  SizedBox(height: 24.h),
                  _buildSectionTitle('Special Instructions (Optional)'),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _instructionsController,
                    maxLines: 3,
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'e.g., No onions, extra spicy, allergic to nuts...',
                      hintStyle: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textTertiary,
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),
                  _buildQuantitySelector(),
                ],
              ),
            ),
          ),

          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200.h,
      color: AppColorsDark.surfaceContainer,
      child: Icon(
        Icons.fastfood,
        size: 80.sp,
        color: AppColorsDark.textTertiary,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium().copyWith(
        color: AppColorsDark.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildVariantSelector() {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children:
          widget.product.variants.map((variant) {
            final isSelected = _selectedVariant?.id == variant.id;
            return InkWell(
              onTap:
                  variant.isAvailable
                      ? () => setState(() => _selectedVariant = variant)
                      : null,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColorsDark.primary.withOpacity(0.2)
                          : AppColorsDark.surfaceVariant,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColorsDark.primary
                            : AppColorsDark.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      variant.name,
                      style: AppTextStyles.titleSmall().copyWith(
                        color:
                            isSelected
                                ? AppColorsDark.primary
                                : AppColorsDark.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // ✅ FIXED: Show as full price "PKR 750", not "+PKR 750"
                    Text(
                      'PKR ${variant.price.toInt()}',
                      style: AppTextStyles.bodySmall().copyWith(
                        color:
                            isSelected
                                ? AppColorsDark.primary
                                : AppColorsDark.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAddonsSelector() {
    return Column(
      children:
          widget.product.addons.map((addon) {
            final isSelected = _selectedAddons.any((a) => a.id == addon.id);
            return CheckboxListTile(
              value: isSelected,
              onChanged:
                  addon.isAvailable
                      ? (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedAddons.add(addon);
                          } else {
                            _selectedAddons.removeWhere(
                              (a) => a.id == addon.id,
                            );
                          }
                        });
                      }
                      : null,
              title: Text(
                addon.name,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                ),
              ),
              subtitle: Text(
                '+PKR ${addon.price.toInt()}',
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColorsDark.primary,
            );
          }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Text(
          'Quantity',
          style: AppTextStyles.titleSmall().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: AppColorsDark.surfaceVariant,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove, size: 20.sp),
                onPressed:
                    _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  '$_quantity',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, size: 20.sp),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
      ],
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),
                  Text(
                    'PKR ${_calculateTotal().toInt()}',
                    style: AppTextStyles.headlineSmall().copyWith(
                      color: AppColorsDark.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  widget.onAddToCart(
                    widget.product,
                    _selectedVariant,
                    _selectedAddons,
                    _instructionsController.text.trim().isEmpty
                        ? null
                        : _instructionsController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: const Text('Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
