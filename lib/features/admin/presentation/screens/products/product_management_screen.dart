// lib/features/admin/presentation/screens/products/product_management_screen.dart

import 'package:abw_app/features/admin/presentation/screens/products/widgets/add_edit_product_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../products/presentation/providers/products_provider.dart';
import '../../../../products/data/models/product_model.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../stores/presentation/providers/stores_provider.dart';
import 'widgets/add_product_dialog.dart';
import 'widgets/product_details_dialog.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedStore = 'all';
  bool _showAvailableOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(productsProvider.notifier).getAllProducts(),
      ref.read(categoriesProvider.notifier).getAllCategories(),
      ref.read(storesProvider.notifier).getApprovedStores(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final storesState = ref.watch(storesProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        elevation: 0,
        title: Text(
          'Product Management',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: AppColorsDark.primary,
              size: 28.sp,
            ),
            onPressed: () => _showAddProductDialog(),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          _buildSearchAndFilters(categoriesState, storesState),
          
          // Products List
          Expanded(
            child: productsState is ProductsLoading
                ? _buildLoadingState()
                : productsState is ProductsError
                    ? _buildErrorState(productsState.error)
                    : productsState is ProductsLoaded
                        ? _buildProductsList(productsState.products)
                        : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    CategoriesState categoriesState,
    StoresState storesState,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColorsDark.surface,
      child: Column(
        children: [
          // Search Bar
          TextField(
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textTertiary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColorsDark.textSecondary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColorsDark.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColorsDark.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          
          SizedBox(height: 12.h),
          
          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Category Filter
                _buildFilterChip(
                  label: _selectedCategory == 'all'
                      ? 'All Categories'
                      : _getCategoryName(categoriesState),
                  icon: Icons.category,
                  onTap: () => _showCategoryFilter(categoriesState),
                ),
                
                SizedBox(width: 8.w),
                
                // Store Filter
                _buildFilterChip(
                  label: _selectedStore == 'all'
                      ? 'All Stores'
                      : _getStoreName(storesState),
                  icon: Icons.store,
                  onTap: () => _showStoreFilter(storesState),
                ),
                
                SizedBox(width: 8.w),
                
                // Available Only Toggle
                _buildFilterChip(
                  label: 'Available Only',
                  icon: _showAvailableOnly
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  isActive: _showAvailableOnly,
                  onTap: () {
                    setState(() => _showAvailableOnly = !_showAvailableOnly);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive
              ? AppColorsDark.primary.withOpacity(0.2)
              : AppColorsDark.surfaceVariant,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isActive
                ? AppColorsDark.primary
                : AppColorsDark.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isActive
                  ? AppColorsDark.primary
                  : AppColorsDark.textSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: AppTextStyles.bodySmall().copyWith(
                color: isActive
                    ? AppColorsDark.primary
                    : AppColorsDark.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColorsDark.primary),
          SizedBox(height: 16.h),
          Text(
            'Loading products...',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
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
            'Error loading products',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 80.sp,
            color: AppColorsDark.textTertiary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No products yet',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add your first product to get started',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _showAddProductDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<ProductModel> allProducts) {
    // Apply filters
    var filteredProducts = allProducts.where((product) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!product.name.toLowerCase().contains(query) &&
            !product.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'all' &&
          product.categoryId != _selectedCategory) {
        return false;
      }

      // Store filter
      if (_selectedStore != 'all' && product.storeId != _selectedStore) {
        return false;
      }

      // Available filter
      if (_showAvailableOnly && !product.isAvailable) {
        return false;
      }

      return true;
    }).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: AppColorsDark.textTertiary,
            ),
            SizedBox(height: 16.h),
            Text(
              'No products found',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try adjusting your filters',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColorsDark.primary,
      backgroundColor: AppColorsDark.surface,
      child: GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.7,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return _buildProductCard(product);
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
          border: Border.all(
            color: AppColorsDark.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: AppColorsDark.surfaceContainer,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.fastfood,
                      size: 48.sp,
                      color: AppColorsDark.textTertiary,
                    ),
                  ),
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
                      color: product.isAvailable
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
            Expanded(
              child: Padding(
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
                    
                    SizedBox(height: 4.h),
                    
                    // Store Name
                    Text(
                      product.storeName,
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
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
                    
                    SizedBox(height: 8.h),
                    
                    // Stock Info
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 14.sp,
                          color: product.quantity > 0
                              ? AppColorsDark.success
                              : AppColorsDark.error,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Stock: ${product.quantity}',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: product.quantity > 0
                                ? AppColorsDark.success
                                : AppColorsDark.error,
                          ),
                        ),
                        const Spacer(),
                        
                        // More Options
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 18.sp,
                            color: AppColorsDark.textSecondary,
                          ),
                          color: AppColorsDark.surface,
                          onSelected: (value) =>
                              _handleProductAction(value, product),
                          itemBuilder: (context) => [
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
                                  Text(product.isAvailable
                                      ? 'Mark Unavailable'
                                      : 'Mark Available'),
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
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getCategoryName(CategoriesState state) {
    if (state is CategoriesLoaded) {
      final category = state.categories
          .firstWhere((c) => c.id == _selectedCategory, orElse: () => state.categories.first);
      return category.name;
    }
    return 'Category';
  }

  String _getStoreName(StoresState state) {
    if (state is StoresLoaded) {
      final store = state.stores
          .firstWhere((s) => s.id == _selectedStore, orElse: () => state.stores.first);
      return store.name;
    }
    return 'Store';
  }

  void _showCategoryFilter(CategoriesState state) {
    if (state is! CategoriesLoaded) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorsDark.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Category',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: const Icon(Icons.all_inclusive, color: AppColorsDark.primary),
              title: const Text('All Categories'),
              selected: _selectedCategory == 'all',
              selectedTileColor: AppColorsDark.primaryContainer.withOpacity(0.2),
              onTap: () {
                setState(() => _selectedCategory = 'all');
                Navigator.pop(context);
              },
            ),
            ...state.categories.map((category) => ListTile(
              leading: const Icon(Icons.category, color: AppColorsDark.accent),
              title: Text(category.name),
              selected: _selectedCategory == category.id,
              selectedTileColor: AppColorsDark.primaryContainer.withOpacity(0.2),
              onTap: () {
                setState(() => _selectedCategory = category.id);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showStoreFilter(StoresState state) {
    if (state is! StoresLoaded) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorsDark.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Store',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: const Icon(Icons.all_inclusive, color: AppColorsDark.primary),
              title: const Text('All Stores'),
              selected: _selectedStore == 'all',
              selectedTileColor: AppColorsDark.primaryContainer.withOpacity(0.2),
              onTap: () {
                setState(() => _selectedStore = 'all');
                Navigator.pop(context);
              },
            ),
            ...state.stores.map((store) => ListTile(
              leading: const Icon(Icons.store, color: AppColorsDark.success),
              title: Text(store.name),
              selected: _selectedStore == store.id,
              selectedTileColor: AppColorsDark.primaryContainer.withOpacity(0.2),
              onTap: () {
                setState(() => _selectedStore = store.id);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  // Action handlers
  void _handleProductAction(String action, ProductModel product) async {
    switch (action) {
      case 'view':
        _showProductDetails(product);
        break;
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'toggle':
        await _toggleProductAvailability(product);
        break;
      case 'delete':
        _showDeleteDialog(product);
        break;
    }
  }

  Future<void> _toggleProductAvailability(ProductModel product) async {
    final success = await ref.read(productsProvider.notifier).toggleAvailability(
          product.id,
          product.storeId,
          !product.isAvailable,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} marked as ${!product.isAvailable ? 'available' : 'unavailable'}',
          ),
          backgroundColor: AppColorsDark.info,
        ),
      );
    }
  }

  void _showProductDetails(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsDialog(product: product),
    );
  }

void _showAddProductDialog() {
  showDialog(
    context: context,
    builder: (context) => const AddEditProductDialog(),
  );
}

 void _showEditProductDialog(ProductModel product) {
  showDialog(
    context: context,
    builder: (context) => AddEditProductDialog(product: product),
  );
}

  void _showDeleteDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Delete Product',
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
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(productsProvider.notifier).deleteProduct(
                    product.id,
                    product.storeId,
                  );
              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} deleted'),
                    backgroundColor: AppColorsDark.error,
                  ),
                );
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