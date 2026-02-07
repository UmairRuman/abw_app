// lib/features/customer/presentation/screens/home/customer_home_screen.dart

// COMPLETE REPLACEMENT:

import 'package:abw_app/features/stores/data/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../stores/presentation/providers/stores_provider.dart';
import '../../../../products/presentation/providers/products_provider.dart';
import '../../../../cart/presentation/providers/cart_provider.dart';

import '../../../../products/data/models/product_model.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  String _selectedCategoryId =
      ''; // Will be set to first category (food) in initState
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Load categories first
    await ref.read(categoriesProvider.notifier).getAllCategories();

    // Set default category to first category (should be food)
    final categoriesState = ref.read(categoriesProvider);
    if (categoriesState is CategoriesLoaded &&
        categoriesState.categories.isNotEmpty) {
      setState(() {
        _selectedCategoryId = categoriesState.categories.first.id;
        _isInitialized = true;
      });
    }

    // Load other data
    await Future.wait([
      ref.read(storesProvider.notifier).getAllStores(),
      ref.read(productsProvider.notifier).getFeaturedProducts(),
      _loadCart(),
    ]);
  }

  Future<void> _loadCart() async {
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      await ref.read(cartProvider.notifier).loadCart(authState.user.id);
    }
  }

  void _onCategoryChanged(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    // Reload products for selected category
    if (categoryId.isEmpty) {
      ref.read(productsProvider.notifier).getFeaturedProducts();
    } else {
      ref.read(productsProvider.notifier).getProductsByCategory(categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final storesState = ref.watch(storesProvider);
    final productsState = ref.watch(productsProvider);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColorsDark.primary,
          backgroundColor: AppColorsDark.surface,
          child: CustomScrollView(
            slivers: [
              // App Bar
              _buildSliverAppBar(cartState),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: _buildSearchBar(),
                ),
              ),

              // Category Filter Chips (Horizontal)
              if (categoriesState is CategoriesLoaded && _isInitialized)
                SliverToBoxAdapter(child: _buildCategoryChips(categoriesState)),

              // Featured Products Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategoryId.isEmpty
                            ? 'Featured Products'
                            : 'Products',
                        style: AppTextStyles.titleLarge().copyWith(
                          color: AppColorsDark.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/customer/search');
                        },
                        child: Text(
                          'See All',
                          style: AppTextStyles.labelMedium().copyWith(
                            color: AppColorsDark.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Products Grid
              if (productsState is ProductsLoaded)
                _buildProductsGrid(productsState)
              else if (productsState is ProductsLoading)
                SliverToBoxAdapter(child: _buildLoadingState())
              else if (productsState is ProductsError)
                SliverToBoxAdapter(
                  child: _buildErrorState(productsState.error),
                ),

              // Featured Stores Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
                  child: Text(
                    'Featured Stores',
                    style: AppTextStyles.titleLarge().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (storesState is StoresLoaded)
                SliverToBoxAdapter(child: _buildFeaturedStores(storesState))
              else if (storesState is StoresLoading)
                SliverToBoxAdapter(child: _buildLoadingState()),

              // All Stores Section (Non-Featured)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategoryId.isEmpty
                            ? 'All Stores'
                            : 'Stores in Category',
                        style: AppTextStyles.titleLarge().copyWith(
                          color: AppColorsDark.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (storesState is StoresLoaded)
                        Text(
                          '${_getNonFeaturedStores(storesState).length} stores',
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Store List (Non-Featured)
              if (storesState is StoresLoaded)
                _buildStoreList(storesState)
              else if (storesState is StoresLoading)
                SliverToBoxAdapter(child: _buildLoadingState())
              else if (storesState is StoresError)
                SliverToBoxAdapter(child: _buildErrorState(storesState.error)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCartFAB(cartState),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildSliverAppBar(CartState cartState) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColorsDark.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deliver to',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16.sp,
                color: AppColorsDark.primary,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  'Current Location',
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20.sp,
                color: AppColorsDark.textPrimary,
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppColorsDark.textPrimary,
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          color: AppColorsDark.textPrimary,
          onPressed: () {
            context.push('/customer/profile');
          },
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return InkWell(
      onTap: () {
        context.push('/customer/search');
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsDark.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColorsDark.textSecondary, size: 24.sp),
            SizedBox(width: 12.w),
            Text(
              'Search for products or stores',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textTertiary,
              ),
            ),
            const Spacer(),
            Icon(Icons.tune, color: AppColorsDark.textSecondary, size: 24.sp),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY CHIPS (HORIZONTAL FILTER)
  // ============================================================

  Widget _buildCategoryChips(CategoriesLoaded state) {
    final categories = state.categories;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            // All chip
            _buildCategoryChip(
              id: '',
              name: 'All',
              icon: Icons.apps,
              isSelected: _selectedCategoryId.isEmpty,
            ),
            SizedBox(width: 8.w),

            // Category chips
            ...categories.map(
              (category) => Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _buildCategoryChip(
                  id: category.id,
                  name: category.name,
                  icon: _getCategoryIcon(category.name),
                  isSelected: _selectedCategoryId == category.id,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String id,
    required String name,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _onCategoryChanged(id),
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColorsDark.primary : AppColorsDark.surfaceVariant,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColorsDark.primary : AppColorsDark.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color:
                  isSelected ? AppColorsDark.white : AppColorsDark.textPrimary,
            ),
            SizedBox(width: 6.w),
            Text(
              name,
              style: AppTextStyles.labelMedium().copyWith(
                color:
                    isSelected
                        ? AppColorsDark.white
                        : AppColorsDark.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('food') || name.contains('restaurant')) {
      return Icons.restaurant;
    } else if (name.contains('grocery')) {
      return Icons.shopping_basket;
    } else if (name.contains('pharmacy') || name.contains('medicine')) {
      return Icons.local_pharmacy;
    } else if (name.contains('electronics')) {
      return Icons.devices;
    } else if (name.contains('fashion') || name.contains('clothing')) {
      return Icons.checkroom;
    }
    return Icons.category;
  }

  // ============================================================
  // PRODUCTS GRID
  // ============================================================

  Widget _buildProductsGrid(ProductsLoaded state) {
    final products = state.products.take(6).toList(); // Show first 6 products

    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
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
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          return _buildProductCard(product);
        }, childCount: products.length),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return InkWell(
      onTap: () {
        // Navigate to product details
        context.push('/customer/store/${product.storeId}');
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsDark.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    topRight: Radius.circular(12.r),
                  ),
                  child:
                      product.images.isNotEmpty
                          ? Image.network(
                            product.images.first,
                            width: double.infinity,
                            height: 120.h,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildProductPlaceholder(),
                          )
                          : _buildProductPlaceholder(),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Availability Badge
                if (!product.isAvailable)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorsDark.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Out of Stock',
                        style: AppTextStyles.labelSmall().copyWith(
                          color: AppColorsDark.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: AppTextStyles.bodyMedium().copyWith(
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

                    // Price & Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.discount > 0)
                              Text(
                                'PKR ${product.price.toInt()}',
                                style: AppTextStyles.bodySmall().copyWith(
                                  color: AppColorsDark.textTertiary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              'PKR ${product.discountedPrice.toInt()}',
                              style: AppTextStyles.titleSmall().copyWith(
                                color: AppColorsDark.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // Add Button
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: AppColorsDark.primary,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.add,
                            color: AppColorsDark.white,
                            size: 18.sp,
                          ),
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

  Widget _buildProductPlaceholder() {
    return Container(
      width: double.infinity,
      height: 120.h,
      color: AppColorsDark.surfaceContainer,
      child: Icon(
        Icons.image_outlined,
        size: 40.sp,
        color: AppColorsDark.textTertiary,
      ),
    );
  }

  // ============================================================
  // FEATURED STORES
  // ============================================================

  Widget _buildFeaturedStores(StoresLoaded state) {
    final featuredStores =
        state.stores
            .where(
              (store) =>
                  store.isFeatured &&
                  store.isActive &&
                  (_selectedCategoryId.isEmpty ||
                      store.categoryId == _selectedCategoryId),
            )
            .take(5)
            .toList();

    if (featuredStores.isEmpty) {
      return SizedBox(height: 16.h);
    }

    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: featuredStores.length,
        itemBuilder: (context, index) {
          final store = featuredStores[index];
          return _buildFeaturedCard(store);
        },
      ),
    );
  }

  Widget _buildFeaturedCard(StoreModel store) {
    return Container(
      width: 300.w,
      margin: EdgeInsets.only(right: 12.w),
      child: InkWell(
        onTap: () {
          context.push('/customer/store/${store.id}');
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColorsDark.cardGradient,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColorsDark.border),
          ),
          child: Stack(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child:
                    store.bannerUrl.isNotEmpty
                        ? Image.network(
                          store.bannerUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => _buildStorePlaceholder(),
                        )
                        : _buildStorePlaceholder(),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColorsDark.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 12.h,
                left: 12.w,
                right: 12.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14.sp,
                          color: AppColorsDark.foodRating,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.white,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.access_time,
                          size: 14.sp,
                          color: AppColorsDark.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${store.deliveryTime} min',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Featured Badge
              Positioned(
                top: 12.h,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColorsDark.primary,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'FEATURED',
                    style: AppTextStyles.labelSmall().copyWith(
                      color: AppColorsDark.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ALL STORES (NON-FEATURED)
  // ============================================================

  List<StoreModel> _getNonFeaturedStores(StoresLoaded state) {
    // Get stores that are NOT featured
    return state.stores
        .where(
          (s) =>
              !s.isFeatured && // NOT featured
              s.isActive &&
              (_selectedCategoryId.isEmpty ||
                  s.categoryId == _selectedCategoryId),
        )
        .toList();
  }

  Widget _buildStoreList(StoresLoaded state) {
    final stores = _getNonFeaturedStores(state);

    if (stores.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60.h),
            child: Column(
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 64.sp,
                  color: AppColorsDark.textTertiary,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No stores found',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final store = stores[index];
        return _buildStoreCard(store);
      }, childCount: stores.length),
    );
  }

  Widget _buildStoreCard(StoreModel store) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: InkWell(
        onTap: () {
          context.push('/customer/store/${store.id}');
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColorsDark.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColorsDark.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child:
                    store.logoUrl.isNotEmpty
                        ? Image.network(
                          store.logoUrl,
                          width: 100.w,
                          height: 100.w,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => _buildSmallPlaceholder(),
                        )
                        : _buildSmallPlaceholder(),
              ),

              SizedBox(width: 12.w),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      store.type.toUpperCase(),
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16.sp,
                          color: AppColorsDark.foodRating,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textPrimary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '(${store.totalReviews})',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.sp,
                          color: AppColorsDark.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${store.deliveryTime} min',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.delivery_dining,
                          size: 14.sp,
                          color: AppColorsDark.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'PKR ${store.deliveryFee.toInt()}',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color:
                      store.isOpen
                          ? AppColorsDark.success.withOpacity(0.2)
                          : AppColorsDark.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  store.isOpen ? 'OPEN' : 'CLOSED',
                  style: AppTextStyles.labelSmall().copyWith(
                    color:
                        store.isOpen
                            ? AppColorsDark.success
                            : AppColorsDark.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PLACEHOLDERS & LOADING
  // ============================================================

  Widget _buildStorePlaceholder() {
    return Container(
      color: AppColorsDark.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 60.sp,
          color: AppColorsDark.textTertiary,
        ),
      ),
    );
  }

  Widget _buildSmallPlaceholder() {
    return Container(
      width: 100.w,
      height: 100.w,
      color: AppColorsDark.surfaceContainer,
      child: Icon(Icons.store, size: 40.sp, color: AppColorsDark.textTertiary),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.h),
        child: const CircularProgressIndicator(color: AppColorsDark.primary),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.h),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: AppColorsDark.error),
            SizedBox(height: 16.h),
            Text(
              'Something went wrong',
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
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CART FAB
  // ============================================================

  Widget _buildCartFAB(CartState cartState) {
    if (cartState is! CartLoaded || cartState.cart.isEmpty) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () {
        context.push('/customer/cart');
      },
      backgroundColor: AppColorsDark.primary,
      icon: const Icon(Icons.shopping_cart, color: AppColorsDark.white),
      label: Row(
        children: [
          Text(
            '${cartState.cart.totalItems} items',
            style: AppTextStyles.labelMedium().copyWith(
              color: AppColorsDark.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(' • ', style: TextStyle(color: AppColorsDark.white)),
          Text(
            'PKR ${cartState.cart.total.toInt()}',
            style: AppTextStyles.labelMedium().copyWith(
              color: AppColorsDark.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
