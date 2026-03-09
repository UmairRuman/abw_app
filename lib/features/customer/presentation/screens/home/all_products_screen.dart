// lib/features/customer/presentation/screens/home/all_products_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../products/presentation/providers/products_provider.dart';
import '../../../../products/data/models/product_model.dart';

class AllProductsScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final String? initialCategoryName;

  const AllProductsScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  ConsumerState<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends ConsumerState<AllProductsScreen> {
  final ScrollController _scrollController = ScrollController();

  List<ProductModel> _allProducts = []; // full result from Firestore
  List<ProductModel> _visible = []; // paginated slice shown in grid

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  static const int _pageSize = 12;

  String _selectedCategoryId = '';
  String _selectedCategoryName = 'All';

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId ?? '';
    _selectedCategoryName = widget.initialCategoryName ?? 'All';
    _scrollController.addListener(_onScroll);

    // ✅ FIX: Wrap in Future.microtask so calls happen AFTER the first build.
    // Without this, the setState() inside _loadAll() fires synchronously
    // during initState — Flutter drops it silently, so the spinner never
    // shows and the products never render on first open.
    Future.microtask(() {
      _loadCategories();
      _loadAll();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore) {
      _showNextPage();
    }
  }

  Future<void> _loadCategories() async {
    await ref.read(categoriesProvider.notifier).getActiveCategories();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _allProducts = [];
      _visible = [];
      _hasMore = false;
    });

    try {
      if (_selectedCategoryId.isEmpty) {
        _allProducts =
            await ref.read(productsProvider.notifier).fetchAllProducts();
      } else {
        _allProducts = await ref
            .read(productsProvider.notifier)
            .fetchProductsByCategory(_selectedCategoryId);
      }
    } catch (e) {
      debugPrint('AllProductsScreen load error: $e');
      _allProducts = [];
    }

    _appendPage();
    setState(() => _isLoading = false);
  }

  void _showNextPage() {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _appendPage();
    setState(() => _isLoadingMore = false);
  }

  void _appendPage() {
    final start = _visible.length;
    final end = (start + _pageSize).clamp(0, _allProducts.length);
    if (start >= _allProducts.length) {
      _hasMore = false;
      return;
    }
    _visible.addAll(_allProducts.sublist(start, end));
    _hasMore = end < _allProducts.length;
  }

  void _onCategoryChanged(String id, String name) {
    if (_selectedCategoryId == id) return;
    setState(() {
      _selectedCategoryId = id;
      _selectedCategoryName = name;
    });
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          _selectedCategoryId.isEmpty ? 'All Products' : _selectedCategoryName,
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColorsDark.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Category chips
          if (categoriesState is CategoriesLoaded)
            Container(
              color: AppColorsDark.surface,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    _chip('', 'All', _selectedCategoryId.isEmpty),
                    ...categoriesState.categories.map(
                      (c) => _chip(c.id, c.name, _selectedCategoryId == c.id),
                    ),
                  ],
                ),
              ),
            ),

          // Count
          if (!_isLoading && _allProducts.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                'Showing ${_visible.length} of ${_allProducts.length} products',
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
            ),

          // Grid
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColorsDark.primary,
                      ),
                    )
                    : _visible.isEmpty
                    ? _empty()
                    : RefreshIndicator(
                      onRefresh: _loadAll,
                      color: AppColorsDark.primary,
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _visible.length + (_isLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _visible.length) return _shimmer();
                          return _productCard(_visible[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String id, String name, bool selected) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: InkWell(
        onTap: () => _onCategoryChanged(id, name),
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color:
                selected ? AppColorsDark.primary : AppColorsDark.surfaceVariant,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected ? AppColorsDark.primary : AppColorsDark.border,
            ),
          ),
          child: Text(
            name,
            style: AppTextStyles.labelMedium().copyWith(
              color: selected ? AppColorsDark.white : AppColorsDark.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _productCard(ProductModel product) {
    return InkWell(
      onTap:
          () => Navigator.pushNamed(
            context,
            '/customer/store/${product.storeId}',
          ),
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
                      product.images.isNotEmpty
                          ? Image.network(
                            product.images.first,
                            width: double.infinity,
                            height: 130.h,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imgPlaceholder(),
                          )
                          : _imgPlaceholder(),
                ),
                if (product.discount > 0)
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
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '${product.discount.toInt()}% OFF',
                        style: AppTextStyles.labelSmall().copyWith(
                          color: AppColorsDark.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                  ),
                if (!product.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.r),
                          topRight: Radius.circular(12.r),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Unavailable',
                          style: AppTextStyles.labelSmall().copyWith(
                            color: AppColorsDark.white,
                          ),
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
                      product.name,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      product.storeName,
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
                            if (product.discount > 0)
                              Text(
                                'PKR ${product.price.toInt()}',
                                style: AppTextStyles.bodySmall().copyWith(
                                  color: AppColorsDark.textTertiary,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 10.sp,
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
    );
  }

  Widget _imgPlaceholder() => Container(
    width: double.infinity,
    height: 130.h,
    color: AppColorsDark.surfaceContainer,
    child: Icon(
      Icons.image_outlined,
      size: 36.sp,
      color: AppColorsDark.textTertiary,
    ),
  );

  Widget _shimmer() => Container(
    decoration: BoxDecoration(
      color: AppColorsDark.surfaceContainer,
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: const Center(
      child: CircularProgressIndicator(
        color: AppColorsDark.primary,
        strokeWidth: 2,
      ),
    ),
  );

  Widget _empty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
        SizedBox(height: 8.h),
        Text(
          'Try selecting a different category',
          style: AppTextStyles.bodySmall().copyWith(
            color: AppColorsDark.textSecondary,
          ),
        ),
      ],
    ),
  );
}
