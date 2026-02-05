// lib/features/customer/presentation/screens/store/store_details_screen.dart

import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:abw_app/features/categories/presentation/providers/categories_provider.dart';
import 'package:abw_app/features/stores/data/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../stores/presentation/providers/stores_provider.dart';
import '../../../../products/presentation/providers/products_provider.dart';
import '../../../../cart/presentation/providers/cart_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../products/data/models/product_model.dart';

class StoreDetailsScreen extends ConsumerStatefulWidget {
  final String storeId;

  const StoreDetailsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends ConsumerState<StoreDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarExpanded = true;

  final List<String> _filterOptions = ['All', 'Vegetarian', 'Popular', 'New'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _scrollController.addListener(_scrollListener);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(
      const Duration(milliseconds: 200),
    ); // Ensure context is available
    await Future.wait([
      ref.read(storesProvider.notifier).getStore(widget.storeId),
      ref.read(productsProvider.notifier).getProductsByStore(widget.storeId),
      _loadCart(),
    ]);
  }

  Future<void> _loadCart() async {
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      await ref.read(cartProvider.notifier).loadCart(authState.user.id);
    }
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && _isAppBarExpanded) {
      setState(() => _isAppBarExpanded = false);
    } else if (_scrollController.offset <= 200 && !_isAppBarExpanded) {
      setState(() => _isAppBarExpanded = true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storesState = ref.watch(storesProvider);
    final productsState = ref.watch(productsProvider);
    final cartState = ref.watch(cartProvider);

    if (storesState is StoresLoading) {
      return const Scaffold(
        backgroundColor: AppColorsDark.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColorsDark.primary),
        ),
      );
    }

    if (storesState is! StoreSingleLoaded) {
      return const Scaffold(
        backgroundColor: AppColorsDark.background,
        body: Center(child: Text('Store not found')),
      );
    }

    final store = storesState.store;

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(store),
            _buildStoreInfo(store),
            _buildFilters(),
          ];
        },
        body:
            productsState is ProductsLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColorsDark.primary,
                  ),
                )
                : productsState is ProductsLoaded
                ? _buildProductsList(productsState)
                : const Center(child: Text('No products available')),
      ),
      bottomNavigationBar: _buildCartButton(cartState),
    );
  }

  Widget _buildSliverAppBar(StoreModel store) {
    return SliverAppBar(
      expandedHeight: 250.h,
      pinned: true,
      backgroundColor: AppColorsDark.surface,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColorsDark.background.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: AppColorsDark.white,
            size: 20.sp,
          ),
        ),
        onPressed: () {
          ref.read(categoriesProvider.notifier).getAllCategories();
          ref.read(storesProvider.notifier).getAllStores();
          _loadCart();
          context.pop();
        },
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColorsDark.background.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              color: AppColorsDark.white,
              size: 20.sp,
            ),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColorsDark.background.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.share, color: AppColorsDark.white, size: 20.sp),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            store.bannerUrl.isNotEmpty
                ? Image.network(
                  store.bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildBannerPlaceholder(),
                )
                : _buildBannerPlaceholder(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColorsDark.background.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      color: AppColorsDark.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 80.sp,
          color: AppColorsDark.textTertiary,
        ),
      ),
    );
  }

  Widget _buildStoreInfo(StoreModel store) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColorsDark.surface,
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name & Rating
            Row(
              children: [
                Expanded(
                  child: Text(
                    store.name,
                    style: AppTextStyles.headlineMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorsDark.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16.sp,
                        color: AppColorsDark.foodRating,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        store.rating.toStringAsFixed(1),
                        style: AppTextStyles.titleSmall().copyWith(
                          color: AppColorsDark.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Description
            if (store.description.isNotEmpty)
              Text(
                store.description,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            SizedBox(height: 12.h),

            // Delivery Info
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: '${store.deliveryTime} min',
                ),
                _buildInfoChip(
                  icon: Icons.delivery_dining,
                  label: 'PKR ${store.deliveryFee.toInt()}',
                ),
                _buildInfoChip(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Min PKR ${store.minimumOrder.toInt()}',
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Status Banner
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color:
                    store.isOpen
                        ? AppColorsDark.success.withOpacity(0.1)
                        : AppColorsDark.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color:
                      store.isOpen
                          ? AppColorsDark.success.withOpacity(0.3)
                          : AppColorsDark.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    store.isOpen ? Icons.check_circle : Icons.schedule,
                    color:
                        store.isOpen
                            ? AppColorsDark.success
                            : AppColorsDark.error,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    store.isOpen
                        ? 'Open Now • Accepting Orders'
                        : 'Closed • Opens at ${store.openingTime}',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color:
                          store.isOpen
                              ? AppColorsDark.success
                              : AppColorsDark.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColorsDark.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppColorsDark.primary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 60.h,
      backgroundColor: AppColorsDark.surface,
      automaticallyImplyLeading: false, // Remove back button
      elevation: 0,
      flexibleSpace: Container(
        color: AppColorsDark.surface,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: _filterOptions.length,
          itemBuilder: (context, index) {
            final filter = _filterOptions[index];
            final isSelected = filter == _selectedFilter;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                },
                selectedColor: AppColorsDark.primary.withOpacity(0.3),
                checkmarkColor: AppColorsDark.primary,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductsList(ProductsLoaded state) {
    var products = state.products;

    // Apply filters
    if (_selectedFilter == 'Vegetarian') {
      products = products.where((p) => p.isVegetarian).toList();
    } else if (_selectedFilter == 'Popular') {
      products = products.where((p) => p.isPopular).toList();
    }
    // TODO: Add 'New' filter based on createdAt

    if (products.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64.sp,
                  color: AppColorsDark.textTertiary,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No products available',
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

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child:
                    product.thumbnail.isNotEmpty
                        ? Image.network(
                          product.thumbnail,
                          width: 90.w,
                          height: 90.w,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => _buildProductPlaceholder(),
                        )
                        : _buildProductPlaceholder(),
              ),

              SizedBox(width: 12.w),

              // Details
              Flexible(
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges Row
                    Row(
                      children: [
                        if (product.isVegetarian)
                          Padding(
                            padding: EdgeInsets.only(right: 6.w),
                            child: Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColorsDark.success,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 8.sp,
                                color: AppColorsDark.success,
                              ),
                            ),
                          ),
                        if (product.isSpicy)
                          Padding(
                            padding: EdgeInsets.only(right: 6.w),
                            child: Icon(
                              Icons.local_fire_department,
                              size: 14.sp,
                              color: AppColorsDark.error,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            product.name,
                            style: AppTextStyles.titleSmall().copyWith(
                              color: AppColorsDark.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),

                    // Description
                    Text(
                      product.shortDescription,
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),

                    // Price & Discount
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'PKR ${product.discountedPrice.toInt()}',
                          style: AppTextStyles.titleMedium().copyWith(
                            color: AppColorsDark.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (product.discount > 0)
                          Text(
                            'PKR ${product.price.toInt()}',
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),

                    // Stock Status
                    if (!product.isAvailable || product.quantity == 0)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          'Out of Stock',
                          style: AppTextStyles.labelSmall().copyWith(
                            color: AppColorsDark.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Add Button
              SizedBox(
                width: 110.w, // fixed safe width
                child: _buildAddButton(product),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductPlaceholder() {
    return Container(
      width: 90.w,
      height: 90.w,
      color: AppColorsDark.surfaceContainer,
      child: Icon(
        Icons.fastfood,
        color: AppColorsDark.textTertiary,
        size: 40.sp,
      ),
    );
  }

  // In store_details_screen.dart - Replace the entire method:

  Widget _buildAddButton(ProductModel product) {
    final cartState = ref.watch(cartProvider);

    // Check if product is in cart and get quantity
    int quantityInCart = 0;
    if (cartState is CartLoaded) {
      try {
        final item = cartState.cart.items.firstWhere(
          (item) => item.productId == product.id,
        );
        quantityInCart = item.quantity;
      } catch (e) {
        // Product not in cart, quantity stays 0
        quantityInCart = 0;
      }
    }

    // If item is unavailable or out of stock
    if (!product.isAvailable || product.quantity == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColorsDark.textTertiary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'Out of Stock',
          style: AppTextStyles.labelSmall().copyWith(
            color: AppColorsDark.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // If product is already in cart, show quantity controls
    if (quantityInCart > 0) {
      return Container(
        decoration: BoxDecoration(
          color: AppColorsDark.primary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decrement button
            InkWell(
              onTap: () => _decrementQuantity(product),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                bottomLeft: Radius.circular(8.r),
              ),
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  quantityInCart > 1 ? Icons.remove : Icons.delete_outline,
                  color: AppColorsDark.white,
                  size: 18.sp,
                ),
              ),
            ),

            // Quantity display
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text(
                '$quantityInCart',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Increment button
            InkWell(
              onTap:
                  quantityInCart < product.maxOrderQuantity
                      ? () => _incrementQuantity(product)
                      : null,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8.r),
                bottomRight: Radius.circular(8.r),
              ),
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(Icons.add, color: AppColorsDark.white, size: 18.sp),
              ),
            ),
          ],
        ),
      );
    }

    // Show add button (product not in cart)
    return InkWell(
      onTap: () => _addToCart(product),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColorsDark.primary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(Icons.add, color: AppColorsDark.white, size: 20.sp),
      ),
    );
  }

  Future<void> _addToCart(ProductModel product) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) {
      // Show login dialog
      return;
    }

    final success = await ref
        .read(cartProvider.notifier)
        .addToCart(authState.user.id, product, 1);

    if (!success && mounted) {
      // Different store detected - show confirmation dialog
      final shouldClear = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: AppColorsDark.surface,
              title: Text(
                'Replace Cart Items?',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                ),
              ),
              content: Text(
                'Your cart contains items from another store. Do you want to clear the cart and add items from this store?',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsDark.primary,
                  ),
                  child: const Text('Replace Cart'),
                ),
              ],
            ),
      );

      if (shouldClear == true && mounted) {
        // Clear and add new item
        final cleared = await ref
            .read(cartProvider.notifier)
            .clearAndAddToCart(authState.user.id, product, 1);

        if (cleared && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} added to cart'),
              backgroundColor: AppColorsDark.success,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } else if (success && mounted) {
      // Same store - show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          backgroundColor: AppColorsDark.success,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _incrementQuantity(ProductModel product) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    await ref
        .read(cartProvider.notifier)
        .incrementQuantity(authState.user.id, product.id);
  }

  Future<void> _decrementQuantity(ProductModel product) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    await ref
        .read(cartProvider.notifier)
        .decrementQuantity(authState.user.id, product.id);
  }

  Widget _buildCartButton(CartState cartState) {
    if (cartState is! CartLoaded || cartState.cart.isEmpty) {
      return const SizedBox.shrink();
    }

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
          onPressed: () {
            context.push('/customer/cart');
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            backgroundColor: AppColorsDark.primary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart,
                color: AppColorsDark.white,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'View Cart (${cartState.cart.totalItems} items)',
                style: AppTextStyles.button().copyWith(
                  color: AppColorsDark.white,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '• PKR ${cartState.cart.total.toInt()}',
                style: AppTextStyles.button().copyWith(
                  color: AppColorsDark.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetails(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailsSheet(product),
    );
  }

  Widget _buildProductDetailsSheet(ProductModel product) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColorsDark.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColorsDark.textTertiary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Image
          if (product.images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: Image.network(
                product.images.first,
                width: double.infinity,
                height: 250.h,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      height: 250.h,
                      color: AppColorsDark.surfaceContainer,
                      child: Icon(
                        Icons.fastfood,
                        size: 80.sp,
                        color: AppColorsDark.textTertiary,
                      ),
                    ),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Badges
                  Row(
                    children: [
                      if (product.isVegetarian)
                        Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColorsDark.success,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.circle,
                              size: 10.sp,
                              color: AppColorsDark.success,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          product.name,
                          style: AppTextStyles.headlineSmall().copyWith(
                            color: AppColorsDark.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Description
                  Text(
                    product.description,
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Price
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'PKR ${product.discountedPrice.toInt()}',
                        style: AppTextStyles.headlineMedium().copyWith(
                          color: AppColorsDark.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (product.discount > 0) ...[
                        Text(
                          'PKR ${product.price.toInt()}',
                          style: AppTextStyles.titleMedium().copyWith(
                            color: AppColorsDark.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),

                        Container(
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
                      ],
                    ],
                  ),

                  if (product.tags.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children:
                          product.tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor:
                                      AppColorsDark.primaryContainer,
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Add to Cart Button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: SafeArea(
              child: ElevatedButton(
                onPressed:
                    product.isAvailable && product.quantity > 0
                        ? () {
                          _addToCart(product);
                          Navigator.pop(context);
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56.h),
                ),
                child: Text(
                  product.isAvailable && product.quantity > 0
                      ? 'Add to Cart'
                      : 'Out of Stock',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
