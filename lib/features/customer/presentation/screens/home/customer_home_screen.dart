// lib/features/customer/presentation/screens/home/customer_home_screen.dart

import 'dart:async';
import 'package:abw_app/core/routes/app_router.dart';
import 'package:abw_app/features/addresses/presentation/providers/addresses_provider.dart';
import 'package:abw_app/features/banners/presentation/providers/banners_provider.dart';
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

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

// ✅ FIX 1: AutomaticKeepAliveClientMixin keeps the tab alive in IndexedStack
// but we also reload whenever the tab becomes visible via a custom trigger.
class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware {
  @override
  bool get wantKeepAlive => true; // ✅ Keep state alive across tab switches

  String _selectedCategoryId = '';
  bool _isInitialized = false;

  // Banner auto-scroll
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  PageRoute<dynamic>? _subscribedRoute;

  @override
  void dispose() {
    if (_subscribedRoute != null) {
      routeObserver.unsubscribe(this);
      _subscribedRoute = null;
    }
    _bannerTimer?.cancel();
    _bannerController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 4. Add didPopNext — fires when returning from store detail screen:
  @override
  void didPopNext() {
    _loadData(); // ← reload stores/products when user comes back
  }

  // ✅ FIX 1: Reload when app resumes from background
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      if (_subscribedRoute != route) {
        if (_subscribedRoute != null) {
          routeObserver.unsubscribe(this);
        }
        routeObserver.subscribe(this, route);
        _subscribedRoute = route;
      }
    }
  }

  void _startBannerTimer(int count) {
    _bannerTimer?.cancel();
    if (count <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _bannerPage = (_bannerPage + 1) % count;
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _bannerPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    await ref.read(categoriesProvider.notifier).getActiveCategories();
    final authState = ref.read(authProvider);
    final categoriesState = ref.read(categoriesProvider);

    if (categoriesState is CategoriesLoaded &&
        categoriesState.categories.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedCategoryId = categoriesState.categories.first.id;
          _isInitialized = true;
        });
      }
    }

    // ✅ FIX 1: Always reload stores on every _loadData call so that
    // returning from a store detail screen shows fresh data.
    await Future.wait([
      ref.read(storesProvider.notifier).getAllStores(),
      _loadCart(),
      if (authState is Authenticated)
        ref
            .read(addressesProvider.notifier)
            .loadDefaultAddress(authState.user.id),
    ]);
  }

  Future<void> _loadCart() async {
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      await ref.read(cartProvider.notifier).loadCart(authState.user.id);
    }
  }

  void _onCategoryChanged(String categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    if (categoryId.isEmpty) {
      ref.read(productsProvider.notifier).getFeaturedProducts();
    } else {
      ref.read(productsProvider.notifier).getProductsByCategory(categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin
    final categoriesState = ref.watch(categoriesProvider);
    final storesState = ref.watch(storesProvider);
    final cartState = ref.watch(cartProvider);
    final bannersAsync = ref.watch(activeBannersStreamProvider);
    final featuredProductsAsync = ref.watch(featuredProductsStreamProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColorsDark.primary,
          backgroundColor: AppColorsDark.surface,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: _buildSearchBar(),
                ),
              ),

              if (categoriesState is CategoriesLoaded && _isInitialized)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: _buildCategoryChips(categoriesState),
                  ),
                ),

              // ── Banners ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: bannersAsync.when(
                  data: (banners) {
                    if (banners.isEmpty) return const SizedBox.shrink();
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _startBannerTimer(banners.length),
                    );
                    return _buildBannerCarousel(banners);
                  },
                  loading: () => _buildBannerSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // ── Featured Items header ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Items',
                        style: AppTextStyles.titleLarge().copyWith(
                          color: AppColorsDark.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/customer/search'),
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

              // ── Featured Items ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: featuredProductsAsync.when(
                  data:
                      (products) =>
                          products.isEmpty
                              // ✅ FIX 4: Empty state for featured products
                              ? _buildEmptyState(
                                icon: Icons.star_border_rounded,
                                title: 'No Featured Items',
                                subtitle:
                                    'Check back soon for featured products',
                              )
                              : _buildFeaturedProductsList(products),
                  loading: () => _buildLoadingState(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // ── Featured Stores header ────────────────────────────────────
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

              // ── Featured Stores ───────────────────────────────────────────
              if (storesState is StoresLoaded)
                SliverToBoxAdapter(child: _buildFeaturedStores(storesState))
              else if (storesState is StoresLoading)
                SliverToBoxAdapter(child: _buildLoadingState()),

              // ── All Stores header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
                  child: Text(
                    _selectedCategoryId.isEmpty
                        ? 'All Stores'
                        : 'Stores in Category',
                    style: AppTextStyles.titleLarge().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // ── All Stores ────────────────────────────────────────────────
              if (storesState is StoresLoaded)
                _buildStoreList(storesState)
              else if (storesState is StoresLoading)
                SliverToBoxAdapter(child: _buildLoadingState()),

              SliverToBoxAdapter(child: SizedBox(height: 80.h)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCartFAB(cartState),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  // ✅ FIX 4: Reusable empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColorsDark.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48.sp, color: AppColorsDark.textTertiary),
            SizedBox(height: 12.h),
            Text(
              title,
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
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

  // ── Banner Carousel ────────────────────────────────────────────────────────

  Widget _buildBannerCarousel(List<BannerModel> banners) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: SizedBox(
              height: 160.h,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _bannerPage = i),
                itemBuilder: (_, index) {
                  final banner = banners[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        banner.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: AppColorsDark.surfaceContainer,
                              child: Icon(
                                Icons.image_outlined,
                                size: 48.sp,
                                color: AppColorsDark.textTertiary,
                              ),
                            ),
                      ),
                      if (banner.title.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Text(
                              banner.title,
                              style: AppTextStyles.titleSmall().copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (banners.length > 1) ...[
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  width: _bannerPage == i ? 20.w : 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color:
                        _bannerPage == i
                            ? AppColorsDark.primary
                            : AppColorsDark.border,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerSkeleton() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      height: 160.h,
      decoration: BoxDecoration(
        color: AppColorsDark.surfaceContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
    );
  }

  // ── Featured Products ──────────────────────────────────────────────────────

  Widget _buildFeaturedProductsList(List<Map<String, dynamic>> rawProducts) {
    return SizedBox(
      height: 240.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: rawProducts.length,
        itemBuilder: (context, index) {
          final data = rawProducts[index];
          final storeId = data['storeId'] as String? ?? '';
          final name = data['name'] as String? ?? '';
          final storeName = data['storeName'] as String? ?? '';
          final price = (data['price'] as num?)?.toDouble() ?? 0;
          final discountedPrice =
              (data['discountedPrice'] as num?)?.toDouble() ?? price;
          final discount = (data['discount'] as num?)?.toDouble() ?? 0;
          final images = data['images'] as List? ?? [];
          final imageUrl = images.isNotEmpty ? images.first as String : '';

          return Container(
            width: 160.w,
            margin: EdgeInsets.only(right: 12.w),
            child: InkWell(
              onTap: () => context.push('/customer/store/$storeId'),
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
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.r),
                            topRight: Radius.circular(12.r),
                          ),
                          child:
                              imageUrl.isNotEmpty
                                  ? Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 120.h,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) =>
                                            _buildProductPlaceholder(),
                                  )
                                  : _buildProductPlaceholder(),
                        ),
                        if (discount > 0)
                          Positioned(
                            top: 8.h,
                            left: 8.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColorsDark.error,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                '${discount.toInt()}% OFF',
                                style: AppTextStyles.labelSmall().copyWith(
                                  color: AppColorsDark.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9.sp,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(10.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.bodyMedium().copyWith(
                                color: AppColorsDark.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              storeName,
                              style: AppTextStyles.bodySmall().copyWith(
                                color: AppColorsDark.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (discount > 0)
                                      Text(
                                        'PKR ${price.toInt()}',
                                        style: AppTextStyles.bodySmall()
                                            .copyWith(
                                              color: AppColorsDark.textTertiary,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                      ),
                                    Text(
                                      'PKR ${discountedPrice.toInt()}',
                                      style: AppTextStyles.titleSmall()
                                          .copyWith(
                                            color: AppColorsDark.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 30.w,
                                  height: 30.w,
                                  decoration: BoxDecoration(
                                    color: AppColorsDark.primary,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: AppColorsDark.white,
                                    size: 16.sp,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductPlaceholder() => Container(
    width: double.infinity,
    height: 120.h,
    color: AppColorsDark.surfaceContainer,
    child: Icon(
      Icons.image_outlined,
      size: 40.sp,
      color: AppColorsDark.textTertiary,
    ),
  );

  // ── Category Chips ─────────────────────────────────────────────────────────

  Widget _buildCategoryChips(CategoriesLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _buildChip('', 'All', Icons.apps, _selectedCategoryId.isEmpty),
          SizedBox(width: 8.w),
          ...state.categories.map(
            (c) => Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: _buildChip(
                c.id,
                c.name,
                _getCategoryIcon(c.name),
                _selectedCategoryId == c.id,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String id, String name, IconData icon, bool isSelected) {
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

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('restaurant')) return Icons.restaurant;
    if (n.contains('grocery')) return Icons.shopping_basket;
    if (n.contains('pharmacy')) return Icons.local_pharmacy;
    if (n.contains('electronics')) return Icons.devices;
    if (n.contains('fashion')) return Icons.checkroom;
    return Icons.category;
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    final addressesState = ref.watch(addressesProvider);
    String locationLabel = 'Set location';
    String locationSub = 'Tap to add address';

    if (addressesState is AddressSingleLoaded) {
      final a = addressesState.address;
      locationLabel = a.label;
      final parts = [
        if (a.addressLine1.isNotEmpty) a.addressLine1,
        if (a.area.isNotEmpty) a.area,
        if (a.city.isNotEmpty) a.city,
      ];
      locationSub = parts.join(', ');
      if (locationSub.length > 40)
        locationSub = '${locationSub.substring(0, 38)}…';
    }

    return SliverAppBar(
      floating: true,
      backgroundColor: AppColorsDark.surface,
      elevation: 0,
      title: GestureDetector(
        onTap: () => context.push('/customer/addresses'),
        child: Row(
          children: [
            Icon(Icons.location_on, size: 22.sp, color: AppColorsDark.primary),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Deliver to  ',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                      Text(
                        locationLabel,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16.sp,
                        color: AppColorsDark.textSecondary,
                      ),
                    ],
                  ),
                  Text(
                    locationSub,
                    style: AppTextStyles.titleSmall().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return InkWell(
      onTap: () => context.push('/customer/search'),
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

  // ── Featured Stores ────────────────────────────────────────────────────────

  Widget _buildFeaturedStores(StoresLoaded state) {
    final featured =
        state.stores
            .where(
              (s) =>
                  s.isFeatured &&
                  s.isActive &&
                  (_selectedCategoryId.isEmpty ||
                      s.categoryId == _selectedCategoryId),
            )
            .take(5)
            .toList();

    // ✅ FIX 4: Empty state for featured stores
    if (featured.isEmpty) {
      return _buildEmptyState(
        icon: Icons.store_outlined,
        title: 'No Featured Stores',
        subtitle: 'No featured stores available for this category',
      );
    }

    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: featured.length,
        itemBuilder: (context, index) => _buildFeaturedCard(featured[index]),
      ),
    );
  }

  Widget _buildFeaturedCard(StoreModel store) {
    return Container(
      width: 300.w,
      margin: EdgeInsets.only(right: 12.w),
      child: InkWell(
        onTap: () => context.push('/customer/store/${store.id}'),
        borderRadius: BorderRadius.circular(16.r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              store.bannerUrl.isNotEmpty
                  ? Image.network(
                    store.bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildStorePlaceholder(),
                  )
                  : _buildStorePlaceholder(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
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
                        color: Colors.white,
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
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.access_time,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${store.deliveryTime} min',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

  // ── Store List ─────────────────────────────────────────────────────────────

  Widget _buildStoreList(StoresLoaded state) {
    final stores =
        state.stores
            .where(
              (s) =>
                  !s.isFeatured &&
                  s.isActive &&
                  (_selectedCategoryId.isEmpty ||
                      s.categoryId == _selectedCategoryId),
            )
            .toList();

    // ✅ FIX 4: Empty state for stores in category
    if (stores.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(
          icon: Icons.storefront_outlined,
          title:
              _selectedCategoryId.isEmpty
                  ? 'No Stores Available'
                  : 'No Stores in This Category',
          subtitle:
              _selectedCategoryId.isEmpty
                  ? 'No stores are currently available. Check back soon!'
                  : 'Try selecting a different category to find more stores.',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildStoreCard(stores[index]),
        childCount: stores.length,
      ),
    );
  }

  Widget _buildStoreCard(StoreModel store) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: InkWell(
        onTap: () => context.push('/customer/store/${store.id}'),
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
                      maxLines: 2,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      store.type.toUpperCase(),
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textTertiary,
                      ),
                    ),
                    SizedBox(height: 8.h),
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
                            color: AppColorsDark.textPrimary,
                          ),
                        ),
                        SizedBox(width: 12.w),
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
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color:
                      store.isCurrentlyOpen
                          ? AppColorsDark.success.withOpacity(0.2)
                          : AppColorsDark.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  store.isCurrentlyOpen ? 'OPEN' : 'CLOSED',
                  style: AppTextStyles.labelSmall().copyWith(
                    color:
                        store.isCurrentlyOpen
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

  Widget _buildStorePlaceholder() => Container(
    color: AppColorsDark.surfaceContainer,
    child: Center(
      child: Icon(
        Icons.restaurant,
        size: 60.sp,
        color: AppColorsDark.textTertiary,
      ),
    ),
  );

  Widget _buildSmallPlaceholder() => Container(
    width: 100.w,
    height: 100.w,
    color: AppColorsDark.surfaceContainer,
    child: Icon(Icons.store, size: 40.sp, color: AppColorsDark.textTertiary),
  );

  Widget _buildLoadingState() => Center(
    child: Padding(
      padding: EdgeInsets.all(40.h),
      child: const CircularProgressIndicator(color: AppColorsDark.primary),
    ),
  );

  Widget _buildCartFAB(CartState cartState) {
    if (cartState is! CartLoaded || cartState.cart.isEmpty)
      return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: () => context.push('/customer/cart'),
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
