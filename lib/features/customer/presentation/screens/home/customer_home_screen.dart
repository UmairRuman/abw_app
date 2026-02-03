// lib/features/customer/presentation/screens/home/customer_home_screen.dart

import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:abw_app/features/stores/data/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../stores/presentation/providers/stores_provider.dart';
import '../../../../cart/presentation/providers/cart_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryId = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed( Duration(milliseconds: 300)); // Small delay for better UX
    await Future.wait([
      ref.read(categoriesProvider.notifier).getActiveCategories(),
      ref.read(storesProvider.notifier).getAllStores(),
      _loadCart(),
    ]);
  }

  Future<void> _loadCart() async {
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      await ref.read(cartProvider.notifier).loadCart(authState.user.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final storesState = ref.watch(storesProvider);
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

              // Categories
              if (categoriesState is CategoriesLoaded)
                SliverToBoxAdapter(
                  child: _buildCategoriesSection(categoriesState),
                ),

              // Featured Stores
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                SliverToBoxAdapter(
                  child: _buildFeaturedStores(storesState),
                )
              else if (storesState is StoresLoading)
                SliverToBoxAdapter(
                  child: _buildLoadingState(),
                ),

              // All Stores
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategoryId == 'all'
                            ? 'All Stores'
                            : 'Stores in Category',
                        style: AppTextStyles.titleLarge().copyWith(
                          color: AppColorsDark.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (storesState is StoresLoaded)
                        Text(
                          '${_getFilteredStores(storesState).length} stores',
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Store List
              if (storesState is StoresLoaded)
                _buildStoreList(storesState)
              else if (storesState is StoresLoading)
                SliverToBoxAdapter(child: _buildLoadingState())
              else if (storesState is StoresError)
                SliverToBoxAdapter(
                  child: _buildErrorState(storesState.error),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCartFAB(cartState),
    );
  }

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
          onPressed: () {
            // TODO: Navigate to notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          color: AppColorsDark.textPrimary,
          onPressed: () {
            context.go('/customer/profile');
          },
        ),
      ],
    );
  }

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
            Icon(
              Icons.search,
              color: AppColorsDark.textSecondary,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'Search for stores or products',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textTertiary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.tune,
              color: AppColorsDark.textSecondary,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(CategoriesLoaded state) {
    final categories = state.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            'Categories',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 110.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: categories.length + 1, // +1 for "All"
            itemBuilder: (context, index) {
              if (index == 0) {
                // "All" category
                return _buildCategoryCard(
                  id: 'all',
                  name: 'All',
                  icon: Icons.grid_view,
                  isSelected: _selectedCategoryId == 'all',
                );
              }

              final category = categories[index - 1];
              return _buildCategoryCard(
                id: category.id,
                name: category.name,
                icon: Icons.category, // TODO: Use actual icon
                isSelected: _selectedCategoryId == category.id,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String id,
    required String name,
    required IconData icon,
    required bool isSelected,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: InkWell(
        onTap: () {
          setState(() => _selectedCategoryId = id);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 85.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: isSelected
                ? AppColorsDark.primaryGradient
                : null,
            color: isSelected ? null : AppColorsDark.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppColorsDark.primary
                  : AppColorsDark.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColorsDark.white.withOpacity(0.2)
                      : AppColorsDark.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColorsDark.white
                      : AppColorsDark.primary,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                name,
                style: AppTextStyles.labelSmall().copyWith(
                  color: isSelected
                      ? AppColorsDark.white
                      : AppColorsDark.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedStores(StoresLoaded state) {
    final featuredStores = state.stores
        .where((store) => store.isFeatured && store.isActive)
        .take(5)
        .toList();

    if (featuredStores.isEmpty) {
      return SizedBox(height: 200.h);
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
                child: store.bannerUrl.isNotEmpty
                    ? Image.network(
                        store.bannerUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
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

  List<dynamic> _getFilteredStores(StoresLoaded state) {
    if (_selectedCategoryId == 'all') {
      return state.stores.where((s) => s.isActive).toList();
    }
    return state.stores
        .where((s) => s.categoryId == _selectedCategoryId && s.isActive)
        .toList();
  }

  Widget _buildStoreList(StoresLoaded state) {
    final stores = _getFilteredStores(state);

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
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final store = stores[index];
          return _buildStoreCard(store as StoreModel);
        },
        childCount: stores.length,
      ),
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
                child: store.logoUrl.isNotEmpty
                    ? Image.network(
                        store.logoUrl,
                        width: 100.w,
                        height: 100.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildSmallPlaceholder(),
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
                  color: store.isOpen
                      ? AppColorsDark.success.withOpacity(0.2)
                      : AppColorsDark.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  store.isOpen ? 'OPEN' : 'CLOSED',
                  style: AppTextStyles.labelSmall().copyWith(
                    color: store.isOpen
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

  Widget _buildPlaceholder() {
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
      child: Icon(
        Icons.store,
        size: 40.sp,
        color: AppColorsDark.textTertiary,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.h),
        child: CircularProgressIndicator(
          color: AppColorsDark.primary,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.h),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48.sp,
              color: AppColorsDark.error,
            ),
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

  Widget _buildCartFAB(CartState cartState) {
    if (cartState is! CartLoaded || cartState.cart.isEmpty) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () {
        context.push('/customer/cart');
      },
      backgroundColor: AppColorsDark.primary,
      icon: Icon(
        Icons.shopping_cart,
        color: AppColorsDark.white,
      ),
      label: Row(
        children: [
          Text(
            '${cartState.cart.totalItems} items',
            style: AppTextStyles.labelMedium().copyWith(
              color: AppColorsDark.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' • ',
            style: TextStyle(color: AppColorsDark.white),
          ),
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