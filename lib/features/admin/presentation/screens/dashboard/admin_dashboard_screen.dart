// lib/features/admin/presentation/screens/dashboard/admin_dashboard_screen.dart

import 'package:abw_app/core/routes/app_router.dart';
import 'package:abw_app/features/admin/presentation/screens/categories/category_management_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../stores/presentation/providers/stores_provider.dart';
import '../../../../products/presentation/providers/products_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading  
    // Load all data for dashboard
    await Future.wait([
      ref.read(categoriesProvider.notifier).getAllCategories(),
      ref.read(storesProvider.notifier).getAllStores(),
      ref.read(productsProvider.notifier).getAllProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColorsDark.primary,
        backgroundColor: AppColorsDark.surface,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildStatsGrid(),
              _buildQuickActions(context),
              _buildPendingApprovals(context),
              _buildRecentStores(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColorsDark.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Dashboard',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Manage your platform',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppColorsDark.textPrimary,
                size: 24.sp,
              ),
              // Notification badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(
                    color: AppColorsDark.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            // TODO: Show notifications
          },
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final categoriesState = ref.watch(categoriesProvider);
    final storesState = ref.watch(storesProvider);
    final productsState = ref.watch(productsProvider);

    // Calculate stats
    int totalCategories = 0;
    int totalStores = 0;
    int pendingStores = 0;
    int totalProducts = 0;

    if (categoriesState is CategoriesLoaded) {
      totalCategories = categoriesState.categories.length;
    }

    if (storesState is StoresLoaded) {
      totalStores = storesState.stores.length;
      pendingStores = storesState.stores
          .where((store) => !store.isApproved)
          .length;
    }

    if (productsState is ProductsLoaded) {
      totalProducts = productsState.products.length;
    }

    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.25,
        ),
        delegate: SliverChildListDelegate([
          _buildStatCard(
            title: 'Categories',
            value: '$totalCategories',
            icon: Icons.category,
            color: AppColorsDark.primary,
            onTap: () {
              // Navigate to categories
            },
          ),
          _buildStatCard(
            title: 'Stores',
            value: '$totalStores',
            icon: Icons.store,
            color: AppColorsDark.success,
            badge: pendingStores > 0 ? '$pendingStores Pending' : null,
            onTap: () {
              // Navigate to stores
            },
          ),
          _buildStatCard(
            title: 'Products',
            value: '$totalProducts',
            icon: Icons.inventory,
            color: AppColorsDark.accent,
            onTap: () {
              // Navigate to products
            },
          ),
          _buildStatCard(
            title: 'Revenue',
            value: 'PKR 0',
            icon: Icons.attach_money,
            color: AppColorsDark.warning,
            subtitle: 'Coming Soon',
            onTap: () {},
          ),
        ]),
      ),
    );
  }

 Widget _buildStatCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  String? badge,
  String? subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16.r),
    child: Container(
      padding: EdgeInsets.all(14.w),
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
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22.sp,
                ),
              ),

              const Spacer(),

              if (badge != null)
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsDark.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall().copyWith(
                        color: AppColorsDark.error,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 8.h),

          /// VALUE
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headlineSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 4.h),

          /// TITLE / SUBTITLE
          Text(
            subtitle ?? title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildQuickActions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.category_rounded,
                    label: 'Add Category',
                    color: AppColorsDark.primary,
                    onTap: () {
                      _showAddCategoryDialog(context);
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.store_rounded,
                    label: 'Add Store',
                    color: AppColorsDark.success,
                    onTap: () {
                      _showAddStoreDialog(context);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.inventory_rounded,
                    label: 'Add Product',
                    color: AppColorsDark.accent,
                    onTap: () {
                      _showAddProductDialog(context);
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.people_rounded,
                    label: 'View Users',
                    color: AppColorsDark.info,
                    onTap: () {
                      _showUsersScreen(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsDark.border),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovals(BuildContext context) {
    final storesState = ref.watch(storesProvider);

    if (storesState is! StoresLoaded) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final pendingStores = storesState.stores
        .where((store) => !store.isApproved)
        .take(3)
        .toList();

    if (pendingStores.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Store Approvals',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to all pending stores
                  },
                  child: Text(
                    'View All',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...pendingStores.map((store) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildApprovalCard(
                name: store.name,
                type: store.type,
                city: store.city,
                onApprove: () async {
                  await ref.read(storesProvider.notifier).approveStore(
                    store.id,
                    'admin-id', // TODO: Get from auth provider
                  );
                  _loadDashboardData();
                },
                onReject: () async {
                  _showRejectDialog(context, store.id);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard({
    required String name,
    required String type,
    required String city,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              gradient: AppColorsDark.primaryGradient,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.store,
              color: AppColorsDark.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$type • $city',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.check_circle_rounded,
                  color: AppColorsDark.success,
                  size: 28.sp,
                ),
                onPressed: onApprove,
              ),
              IconButton(
                icon: Icon(
                  Icons.cancel_rounded,
                  color: AppColorsDark.error,
                  size: 28.sp,
                ),
                onPressed: onReject,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStores() {
    final storesState = ref.watch(storesProvider);

    if (storesState is! StoresLoaded) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final recentStores = storesState.stores
        .where((store) => store.isApproved)
        .take(5)
        .toList();

    if (recentStores.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Stores',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            ...recentStores.map((store) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildStoreItem(
                name: store.name,
                rating: store.rating,
                orders: store.totalOrders,
                isActive: store.isActive,
                onTap: () {
                  // Navigate to store details
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreItem({
    required String name,
    required double rating,
    required int orders,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsDark.border),
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: AppColorsDark.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.store,
                color: AppColorsDark.textSecondary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTextStyles.titleSmall().copyWith(
                            color: AppColorsDark.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColorsDark.success.withOpacity(0.2)
                              : AppColorsDark.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: AppTextStyles.labelSmall().copyWith(
                            color: isActive
                                ? AppColorsDark.success
                                : AppColorsDark.error,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: AppColorsDark.warning,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.shopping_bag,
                        color: AppColorsDark.textTertiary,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '$orders orders',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColorsDark.textTertiary,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
void _showAddCategoryDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const CategoryManagementDialog(),
  );
}

 void _showAddStoreDialog(BuildContext context) {
  // Navigate to store management screen instead
  context.go('/admin/dashboard'); // Stay on dashboard, they can use drawer
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Go to Stores tab to add new store'),
      backgroundColor: AppColorsDark.info,
      action: SnackBarAction(
        label: 'GO',
        textColor: AppColorsDark.white,
        onPressed: () {
          // This will be handled by the main screen tab switching
        },
      ),
    ),
  );
}

 void _showAddProductDialog(BuildContext context) {
  context.goToAdminProducts();
}

void _showUsersScreen(BuildContext context) {
  context.goToAdminUsers();
}

  void _showRejectDialog(BuildContext context, String storeId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Reject Store',
          style: AppTextStyles.titleMedium().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        content: TextField(
          controller: reasonController,
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Reason for rejection',
            hintStyle: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textTertiary,
            ),
          ),
          maxLines: 3,
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
              await ref.read(storesProvider.notifier).rejectStore(
                storeId,
                'admin-id', // TODO: Get from auth provider
                reasonController.text,
              );
              Navigator.pop(context);
              _loadDashboardData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDark.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}