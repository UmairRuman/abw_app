// lib/features/customer/presentation/screens/home/all_stores_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../stores/presentation/providers/stores_provider.dart';
import '../../../../stores/data/models/store_model.dart';

class AllStoresScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final String? initialCategoryName;

  const AllStoresScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  ConsumerState<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends ConsumerState<AllStoresScreen> {
  final ScrollController _scrollController = ScrollController();

  // Pagination state
  final List<StoreModel> _stores = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 10;
  int _currentPage = 0;

  // Filter state
  String _selectedCategoryId = '';
  String _selectedCategoryName = 'All';

  // Sort/Filter
  String _sortBy = 'rating'; // rating | deliveryTime | deliveryFee

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
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate loading delay
    await ref.read(categoriesProvider.notifier).getActiveCategories();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _stores.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    await ref.read(storesProvider.notifier).getAllStores();
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
    final state = ref.read(storesProvider);
    if (state is! StoresLoaded) return;

    // Filter
    var filtered =
        state.stores
            .where(
              (s) =>
                  s.isActive &&
                  (_selectedCategoryId.isEmpty ||
                      s.categoryId == _selectedCategoryId),
            )
            .toList();

    // Sort
    switch (_sortBy) {
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'deliveryTime':
        filtered.sort((a, b) => a.deliveryTime.compareTo(b.deliveryTime));
        break;
      case 'deliveryFee':
        filtered.sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
        break;
    }

    final start = page * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);

    if (start >= filtered.length) {
      setState(() => _hasMore = false);
      return;
    }

    final newItems = filtered.sublist(start, end);
    setState(() {
      _stores.addAll(newItems);
      _currentPage = page;
      _hasMore = end < filtered.length;
    });
  }

  void _onCategoryChanged(String id, String name) {
    setState(() {
      _selectedCategoryId = id;
      _selectedCategoryName = name;
    });
    _loadFirstPage();
  }

  void _onSortChanged(String sort) {
    setState(() => _sortBy = sort);
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
              ? 'All Stores'
              : '$_selectedCategoryName Stores',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),

        actions: [
          // Sort button
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: AppColorsDark.textPrimary),
            onSelected: _onSortChanged,
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: 'rating',
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color:
                              _sortBy == 'rating'
                                  ? AppColorsDark.primary
                                  : AppColorsDark.textSecondary,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        const Text('Top Rated'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'deliveryTime',
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color:
                              _sortBy == 'deliveryTime'
                                  ? AppColorsDark.primary
                                  : AppColorsDark.textSecondary,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        const Text('Fastest Delivery'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'deliveryFee',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          color:
                              _sortBy == 'deliveryFee'
                                  ? AppColorsDark.primary
                                  : AppColorsDark.textSecondary,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        const Text('Lowest Delivery Fee'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category filter ────────────────────────────────────────────
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

          // ── Results count ──────────────────────────────────────────────
          if (!_isLoading)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              color: AppColorsDark.background,
              child: Text(
                '${_stores.length} store${_stores.length != 1 ? 's' : ''}'
                '${_hasMore ? '+' : ''}',
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
            ),

          // ── Stores list ────────────────────────────────────────────────
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColorsDark.primary,
                      ),
                    )
                    : _stores.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                      onRefresh: _loadFirstPage,
                      color: AppColorsDark.primary,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        itemCount: _stores.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _stores.length) {
                            return Padding(
                              padding: EdgeInsets.all(16.h),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColorsDark.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          return _buildStoreCard(_stores[index]);
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

  Widget _buildStoreCard(StoreModel store) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child:
                    store.logoUrl.isNotEmpty
                        ? Image.network(
                          store.logoUrl,
                          width: 90.w,
                          height: 90.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                        )
                        : _buildLogoPlaceholder(),
              ),
              SizedBox(width: 12.w),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: AppTextStyles.titleSmall().copyWith(
                              color: AppColorsDark.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Open/Closed badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                store.isOpen
                                    ? AppColorsDark.success.withOpacity(0.15)
                                    : AppColorsDark.error.withOpacity(0.15),
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
                              fontSize: 9.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      store.type.toUpperCase(),
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textTertiary,
                        fontSize: 10.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Rating + delivery info
                    Wrap(
                      spacing: 12.w,
                      children: [
                        _buildInfoChip(
                          Icons.star,
                          store.rating.toStringAsFixed(1),
                          AppColorsDark.foodRating,
                        ),
                        _buildInfoChip(
                          Icons.access_time,
                          '${store.deliveryTime} min',
                          AppColorsDark.textSecondary,
                        ),
                        _buildInfoChip(
                          Icons.delivery_dining,
                          'PKR ${store.deliveryFee.toInt()}',
                          AppColorsDark.textSecondary,
                        ),
                      ],
                    ),
                    if (store.isFeatured) ...[
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorsDark.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '⭐ Featured',
                          style: AppTextStyles.labelSmall().copyWith(
                            color: AppColorsDark.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.sp, color: color),
        SizedBox(width: 3.w),
        Text(
          label,
          style: AppTextStyles.bodySmall().copyWith(
            color: color,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      width: 90.w,
      height: 90.w,
      color: AppColorsDark.surfaceContainer,
      child: Icon(Icons.store, size: 36.sp, color: AppColorsDark.textTertiary),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
