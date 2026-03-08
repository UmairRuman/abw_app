// lib/features/customer/presentation/screens/home/all_products_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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

  // Pagination state
  final List<ProductModel> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 12;
  int _currentPage = 0;

  // Filter state
  String _selectedCategoryId = '';
  String _selectedCategoryName = 'All';

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId ?? '';
    _selectedCategoryName = widget.initialCategoryName ?? 'All';
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadNextPage();
    }
  }

  Future<void> _loadCategories() async {
    await ref.read(categoriesProvider.notifier).getActiveCategories();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _products.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _fetchPage(0);
    setState(() => _isLoading = false);
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _fetchPage(_currentPage + 1);
    setState(() => _isLoadingMore = false);
  }

  Future<void> _fetchPage(int page) async {
    try {
      // Use the provider to fetch — pass page offset
      if (_selectedCategoryId.isEmpty) {
        await ref.read(productsProvider.notifier).getFeaturedProducts();
      } else {
        await ref
            .read(productsProvider.notifier)
            .getProductsByCategory(_selectedCategoryId);
      }

      final state = ref.read(productsProvider);
      if (state is ProductsLoaded) {
        final allProducts = state.products;
        final start = page * _pageSize;
        final end = (start + _pageSize).clamp(0, allProducts.length);

        if (start >= allProducts.length) {
          setState(() => _hasMore = false);
          return;
        }

        final newItems = allProducts.sublist(start, end);
        setState(() {
          _products.addAll(newItems);
          _currentPage = page;
          _hasMore = end < allProducts.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  void _onCategoryChanged(String id, String name) {
    setState(() {
      _selectedCategoryId = id;
      _selectedCategoryName = name;
    });
    _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          _selectedCategoryName.isEmpty
              ? 'All Products'
              : _selectedCategoryName,
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColorsDark.textPrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Category filter chips ──────────────────────────────────────
          if (categoriesState is CategoriesLoaded)
            Container(
              color: AppColorsDark.surface,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    _buildChip('', 'All', _selectedCategoryId.isEmpty),
                    ...categoriesState.categories.map(
                      (c) =>
                          _buildChip(c.id, c.name, _selectedCategoryId == c.id),
                    ),
                  ],
                ),
              ),
            ),

          // ── Products grid ──────────────────────────────────────────────
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColorsDark.primary,
                      ),
                    )
                    : _products.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                      onRefresh: _loadFirstPage,
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
                        itemCount: _products.length + (_isLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _products.length) {
                            return _buildShimmerCard();
                          }
                          return _buildProductCard(_products[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String id, String name, bool selected) {
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

  Widget _buildProductCard(ProductModel product) {
    return InkWell(
      onTap: () => context.push('/customer/store/${product.storeId}'),
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
            // Image
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
                            errorBuilder:
                                (_, __, ___) => _buildImgPlaceholder(),
                          )
                          : _buildImgPlaceholder(),
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

            // Details
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

  Widget _buildImgPlaceholder() {
    return Container(
      width: double.infinity,
      height: 130.h,
      color: AppColorsDark.surfaceContainer,
      child: Icon(
        Icons.image_outlined,
        size: 36.sp,
        color: AppColorsDark.textTertiary,
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
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
  }

  Widget _buildEmpty() {
    return Center(
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
}
