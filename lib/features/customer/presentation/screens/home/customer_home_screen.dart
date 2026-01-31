// lib/features/customer/presentation/screens/home/customer_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Fast Food',
    'Pizza',
    'Burgers',
    'Asian',
    'Desserts',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            _buildSliverAppBar(),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: _buildSearchBar(),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: _buildCategoriesSection(),
            ),

            // Featured Restaurants
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Text(
                  'Featured Restaurants',
                  style: AppTextStyles.titleLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _buildFeaturedRestaurants(),
            ),

            // All Restaurants
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Text(
                  'All Restaurants',
                  style: AppTextStyles.titleLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
              ),
            ),

            // Restaurant List
            _buildRestaurantList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
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
              Text(
                'Current Location',
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.textPrimary,
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
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColorsDark.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColorsDark.border,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMedium().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search for restaurants or food',
          hintStyle: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColorsDark.textSecondary,
          ),
          suffixIcon: const Icon(
            Icons.tune,
            color: AppColorsDark.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SizedBox(
      height: 50.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              backgroundColor: AppColorsDark.surfaceVariant,
              selectedColor: AppColorsDark.primary,
              labelStyle: AppTextStyles.labelMedium().copyWith(
                color: isSelected
                    ? AppColorsDark.background
                    : AppColorsDark.textPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected
                      ? AppColorsDark.primary
                      : AppColorsDark.border,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedRestaurants() {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: 5, // TODO: Replace with actual data
        itemBuilder: (context, index) {
          return _buildFeaturedCard(index);
        },
      ),
    );
  }

  Widget _buildFeaturedCard(int index) {
    return Container(
      width: 300.w,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        gradient: AppColorsDark.cardGradient,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColorsDark.border,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.network(
              'https://via.placeholder.com/300x200',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColorsDark.surfaceContainer,
                child: Icon(
                  Icons.restaurant,
                  size: 60.sp,
                  color: AppColorsDark.textTertiary,
                ),
              ),
            ),
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
                  'Restaurant Name ${index + 1}',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.white,
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
                      '4.5',
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
                      '30 min',
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
                  color: AppColorsDark.background,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return _buildRestaurantCard(index);
        },
        childCount: 10, // TODO: Replace with actual data
      ),
    );
  }

  Widget _buildRestaurantCard(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColorsDark.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to restaurant details
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  'https://via.placeholder.com/100',
                  width: 100.w,
                  height: 100.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100.w,
                    height: 100.w,
                    color: AppColorsDark.surfaceContainer,
                    child: Icon(
                      Icons.restaurant,
                      size: 40.sp,
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
                    Text(
                      'Restaurant Name ${index + 1}',
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Fast Food, Burgers, Pizza',
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
                          '4.${5 - (index % 5)}',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textPrimary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '(100+)',
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
                          '${25 + (index * 5)} min',
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
                          '\$${2 + (index % 3)}',
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
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsDark.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'OPEN',
                      style: AppTextStyles.labelSmall().copyWith(
                        color: AppColorsDark.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}