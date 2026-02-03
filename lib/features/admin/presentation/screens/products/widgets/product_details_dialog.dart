// lib/features/admin/presentation/screens/products/widgets/product_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../products/data/models/product_model.dart';

class ProductDetailsDialog extends StatelessWidget {
  final ProductModel product;

  const ProductDetailsDialog({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColorsDark.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: 600.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with image
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: AppColorsDark.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.fastfood,
                      size: 80.sp,
                      color: AppColorsDark.textTertiary,
                    ),
                  ),
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColorsDark.textPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  if (product.discount > 0)
                    Positioned(
                      top: 12.h,
                      left: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorsDark.error,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${product.discount.toInt()}% OFF',
                          style: AppTextStyles.labelMedium().copyWith(
                            color: AppColorsDark.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: AppTextStyles.titleLarge().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    // Store & Category
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 16.sp,
                          color: AppColorsDark.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          product.storeName,
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.category,
                          size: 16.sp,
                          color: AppColorsDark.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          product.categoryName,
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    // Status badges
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _buildBadge(
                          label: product.isAvailable ? 'Available' : 'Unavailable',
                          color: product.isAvailable
                              ? AppColorsDark.success
                              : AppColorsDark.error,
                        ),
                        if (product.isFeatured)
                          _buildBadge(
                            label: 'Featured',
                            color: AppColorsDark.accent,
                          ),
                        if (product.isPopular)
                          _buildBadge(
                            label: 'Popular',
                            color: AppColorsDark.warning,
                          ),
                        if (product.isVegetarian)
                          _buildBadge(
                            label: 'Vegetarian',
                            color: AppColorsDark.success,
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 16.h),
                    Divider(color: AppColorsDark.divider),
                    SizedBox(height: 16.h),
                    
                    // Price Section
                    _buildSection(
                      title: 'Pricing',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (product.discount > 0) ...[
                                Text(
                                  'PKR ${product.price.toInt()}',
                                  style: AppTextStyles.titleMedium().copyWith(
                                    color: AppColorsDark.textTertiary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                              ],
                              Text(
                                'PKR ${product.discountedPrice.toInt()}',
                                style: AppTextStyles.headlineSmall().copyWith(
                                  color: AppColorsDark.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Unit: ${product.unit}',
                            style: AppTextStyles.bodyMedium().copyWith(
                              color: AppColorsDark.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    // Stock Section
                    _buildSection(
                      title: 'Stock Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            label: 'Available Stock',
                            value: '${product.quantity} ${product.unit}',
                            color: product.quantity > 0
                                ? AppColorsDark.success
                                : AppColorsDark.error,
                          ),
                          _buildInfoRow(
                            label: 'Min Order',
                            value: '${product.minOrderQuantity} ${product.unit}',
                          ),
                          _buildInfoRow(
                            label: 'Max Order',
                            value: '${product.maxOrderQuantity} ${product.unit}',
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    // Description
                    _buildSection(
                      title: 'Description',
                      child: Text(
                        product.description,
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                    ),
                    
                    if (product.preparationTime > 0) ...[
                      SizedBox(height: 16.h),
                      _buildSection(
                        title: 'Preparation Time',
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 20.sp,
                              color: AppColorsDark.info,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${product.preparationTime} minutes',
                              style: AppTextStyles.bodyMedium().copyWith(
                                color: AppColorsDark.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Stats
                    SizedBox(height: 16.h),
                    _buildSection(
                      title: 'Statistics',
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.star,
                              label: 'Rating',
                              value: product.rating.toStringAsFixed(1),
                              color: AppColorsDark.warning,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.shopping_cart,
                              label: 'Sold',
                              value: '${product.totalSold}',
                              color: AppColorsDark.success,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.rate_review,
                              label: 'Reviews',
                              value: '${product.totalReviews}',
                              color: AppColorsDark.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Tags
                    if (product.tags.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      _buildSection(
                        title: 'Tags',
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: product.tags
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    backgroundColor: AppColorsDark.primaryContainer,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall().copyWith(
            color: AppColorsDark.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall().copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
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
              color: color ?? AppColorsDark.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTextStyles.labelSmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}