// lib/features/customer/presentation/screens/restaurant/restaurant_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class RestaurantDetailsScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  ConsumerState<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState
    extends ConsumerState<RestaurantDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarExpanded = true;

  final List<String> _menuCategories = [
    'Popular',
    'Main Course',
    'Appetizers',
    'Desserts',
    'Beverages',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _menuCategories.length, vsync: this);
    _scrollController.addListener(_scrollListener);
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
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
            _buildRestaurantInfo(),
            _buildTabBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _menuCategories
              .map((category) => _buildMenuList(category))
              .toList(),
        ),
      ),
      bottomNavigationBar: _buildCartButton(),
    );
  }

  Widget _buildSliverAppBar() {
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
        onPressed: () => Navigator.pop(context),
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
            child: Icon(
              Icons.share,
              color: AppColorsDark.white,
              size: 20.sp,
            ),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://via.placeholder.com/400x250',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColorsDark.surfaceContainer,
                child: Icon(
                  Icons.restaurant,
                  size: 80.sp,
                  color: AppColorsDark.textTertiary,
                ),
              ),
            ),
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

  Widget _buildRestaurantInfo() {
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
                    'Restaurant Name',
                    style: AppTextStyles.headlineMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
                        '4.5',
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

            // Cuisine Types
            Text(
              'Fast Food • Burgers • Pizza • American',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),

            SizedBox(height: 12.h),

            // Delivery Info
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: '30-40 min',
                ),
                SizedBox(width: 12.w),
                _buildInfoChip(
                  icon: Icons.delivery_dining,
                  label: '\$2.99',
                ),
                SizedBox(width: 12.w),
                _buildInfoChip(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Min \$15',
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Status Banner
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColorsDark.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColorsDark.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColorsDark.success,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Open Now • Accepting Orders',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.success,
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
          Icon(
            icon,
            size: 16.sp,
            color: AppColorsDark.primary,
          ),
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

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyTabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColorsDark.primary,
          labelColor: AppColorsDark.primary,
          unselectedLabelColor: AppColorsDark.textSecondary,
          labelStyle: AppTextStyles.titleSmall(),
          tabs: _menuCategories
              .map((category) => Tab(text: category))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMenuList(String category) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 8, // TODO: Replace with actual data
      itemBuilder: (context, index) => _buildMenuItemCard(index),
    );
  }

  Widget _buildMenuItemCard(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: InkWell(
        onTap: () => _showItemDetails(),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  'https://via.placeholder.com/80',
                  width: 80.w,
                  height: 80.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80.w,
                    height: 80.w,
                    color: AppColorsDark.surfaceContainer,
                    child: const Icon(
                      Icons.fastfood,
                      color: AppColorsDark.textTertiary,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (index % 3 == 0)
                          Padding(
                            padding: EdgeInsets.only(right: 6.w),
                            child: Icon(
                              Icons.eco,
                              size: 14.sp,
                              color: AppColorsDark.success,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            'Menu Item ${index + 1}',
                            style: AppTextStyles.titleSmall().copyWith(
                              color: AppColorsDark.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Delicious description of the menu item with ingredients',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text(
                          '\$${(12 + index * 2)}.99',
                          style: AppTextStyles.titleMedium().copyWith(
                            color: AppColorsDark.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (index % 4 == 0) ...[
                          SizedBox(width: 8.w),
                          Text(
                            '\$${(15 + index * 2)}.99',
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Add Button
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColorsDark.primary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.add,
                    color: AppColorsDark.background,
                    size: 20.sp,
                  ),
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartButton() {
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
            // TODO: Navigate to cart
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
                color: AppColorsDark.background,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'View Cart (3 items)',
                style: AppTextStyles.button().copyWith(
                  color: AppColorsDark.background,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '• \$42.99',
                style: AppTextStyles.button().copyWith(
                  color: AppColorsDark.background,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItemDetailsSheet(),
    );
  }

  Widget _buildItemDetailsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            child: Image.network(
              'https://via.placeholder.com/400x200',
              width: double.infinity,
              height: 200.h,
              fit: BoxFit.cover,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Name',
                    style: AppTextStyles.headlineSmall().copyWith(
                      color: AppColorsDark.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Full description of the item with all ingredients and preparation details.',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '\$14.99',
                    style: AppTextStyles.headlineMedium().copyWith(
                      color: AppColorsDark.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Add to Cart Button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56.h),
                ),
                child: const Text('Add to Cart'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;

  _StickyTabBarDelegate(this.child);

  @override
  double get minExtent => child.preferredSize.height;
  @override
  double get maxExtent => child.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColorsDark.surface,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}