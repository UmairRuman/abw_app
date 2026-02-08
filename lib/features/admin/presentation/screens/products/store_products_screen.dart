// lib/features/admin/presentation/screens/products/store_products_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../stores/data/models/store_model.dart';
import '../../../../products/presentation/providers/products_provider.dart';
import '../../../../products/data/models/product_model.dart';
import 'widgets/add_edit_product_dialog.dart';
import 'widgets/product_details_dialog.dart';

class StoreProductsScreen extends ConsumerStatefulWidget {
  final StoreModel store;

  const StoreProductsScreen({super.key, required this.store});

  @override
  ConsumerState<StoreProductsScreen> createState() =>
      _StoreProductsScreenState();
}

class _StoreProductsScreenState extends ConsumerState<StoreProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    await Future.delayed(
      const Duration(milliseconds: 300),
    ); // Simulate loading delay
    await ref
        .read(productsProvider.notifier)
        .getProductsByStore(widget.store.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products',
              style: AppTextStyles.titleLarge().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            Text(
              widget.store.name,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColorsDark.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColorsDark.textSecondary,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColorsDark.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                        : null,
              ),
            ),
          ),

          // Products List
          Expanded(
            child:
                productsState is ProductsLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColorsDark.primary,
                      ),
                    )
                    : productsState is ProductsLoaded
                    ? _buildProductsList(productsState)
                    : Center(
                      child: Text(
                        'No products found',
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: AppColorsDark.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildProductsList(ProductsLoaded state) {
    var products = state.products;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      products =
          products
              .where((p) => p.name.toLowerCase().contains(_searchQuery))
              .toList();
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80.sp,
              color: AppColorsDark.textTertiary,
            ),
            SizedBox(height: 16.h),
            Text(
              _searchQuery.isEmpty ? 'No products yet' : 'No products found',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                'Add your first product',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppColorsDark.primary,
      backgroundColor: AppColorsDark.surface,
      child: GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildProductCard(products[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return InkWell(
      onTap: () => _showProductDetails(product),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColorsDark.cardBackground,
              AppColorsDark.surfaceVariant,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColorsDark.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ FIXED: Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                  child:
                      product.thumbnail.isNotEmpty
                          ? Image.network(
                            product.thumbnail,
                            height: 140.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildImagePlaceholder(),
                          )
                          : _buildImagePlaceholder(),
                ),

                // Availability Badge
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          product.isAvailable
                              ? AppColorsDark.success
                              : AppColorsDark.error,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      product.isAvailable ? 'Available' : 'Unavailable',
                      style: AppTextStyles.labelSmall().copyWith(
                        color: AppColorsDark.white,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ),

                // Discount Badge
                if (product.discount > 0)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorsDark.error,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${product.discount.toInt()}% OFF',
                        style: AppTextStyles.labelSmall().copyWith(
                          color: AppColorsDark.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Info
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: AppTextStyles.titleSmall().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 8.h),

                  // Price Row
                  Row(
                    children: [
                      if (product.discount > 0) ...[
                        Text(
                          'PKR ${product.price.toInt()}',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        SizedBox(width: 4.w),
                      ],
                      Text(
                        'PKR ${product.discountedPrice.toInt()}',
                        style: AppTextStyles.titleSmall().copyWith(
                          color: AppColorsDark.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Stock Info
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 14.sp,
                        color:
                            product.quantity > 0
                                ? AppColorsDark.success
                                : AppColorsDark.error,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          'Stock: ${product.quantity}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall().copyWith(
                            color:
                                product.quantity > 0
                                    ? AppColorsDark.success
                                    : AppColorsDark.error,
                          ),
                        ),
                      ),

                      // More Options
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 18.sp,
                          color: AppColorsDark.textSecondary,
                        ),
                        color: AppColorsDark.surface,
                        onSelected:
                            (value) => _handleProductAction(value, product),
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 18.sp),
                                    SizedBox(width: 8.w),
                                    const Text('View'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18.sp),
                                    SizedBox(width: 8.w),
                                    const Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      product.isAvailable
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      product.isAvailable
                                          ? 'Mark Unavailable'
                                          : 'Mark Available',
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 18.sp,
                                      color: AppColorsDark.error,
                                    ),
                                    SizedBox(width: 8.w),
                                    const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: AppColorsDark.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 140.h,
      width: double.infinity,
      color: AppColorsDark.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.fastfood,
          size: 48.sp,
          color: AppColorsDark.textTertiary,
        ),
      ),
    );
  }

  void _handleProductAction(String action, ProductModel product) {
    switch (action) {
      case 'view':
        _showProductDetails(product);
        break;
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'toggle':
        _toggleProductAvailability(product);
        break;
      case 'delete':
        _showDeleteDialog(product);
        break;
    }
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditProductDialog(storeId: widget.store.id),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AddEditProductDialog(product: product),
    );
  }

  void _showProductDetails(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsDialog(product: product),
    );
  }

  Future<void> _toggleProductAvailability(ProductModel product) async {
    final success = await ref
        .read(productsProvider.notifier)
        .toggleAvailability(product.id, product.storeId, !product.isAvailable);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} marked as ${!product.isAvailable ? "available" : "unavailable"}',
          ),
          backgroundColor: AppColorsDark.info,
        ),
      );
    }
  }

  void _showDeleteDialog(ProductModel product) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Delete Product?',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.error,
              ),
            ),
            content: Text(
              'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final success = await ref
                      .read(productsProvider.notifier)
                      .deleteProduct(product.id, product.storeId);

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} deleted successfully'),
                          backgroundColor: AppColorsDark.success,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
