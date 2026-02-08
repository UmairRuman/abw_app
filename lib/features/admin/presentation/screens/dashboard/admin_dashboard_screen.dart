// lib/features/admin/presentation/screens/dashboard/admin_dashboard_screen.dart

import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../stores/presentation/providers/stores_provider.dart';
import '../../../../products/presentation/providers/products_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../categories/category_management_dialog.dart';
import '../restaurants/widgets/add_edit_store_dialog.dart';
import '../products/widgets/add_edit_product_dialog.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate loading delay
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildEnhancedAppBar(),
              _buildWelcomeBanner(),
              _buildEnhancedStatsGrid(),
              _buildQuickActions(),
              _buildPendingApprovals(context),
              _buildRecentActivity(),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ ENHANCED APP BAR
  Widget _buildEnhancedAppBar() {
    final authState = ref.watch(authProvider);
    String adminName = 'Admin';
    if (authState is Authenticated) {
      adminName = authState.user.name;
    }

    return SliverAppBar(
      expandedHeight: 120.h,
      floating: false,
      pinned: true,
      backgroundColor: AppColorsDark.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColorsDark.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Welcome back,',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    adminName,
                    style: AppTextStyles.headlineMedium().copyWith(
                      color: AppColorsDark.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppColorsDark.white,
                size: 24.sp,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: AppColorsDark.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColorsDark.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications coming soon!'),
                backgroundColor: AppColorsDark.info,
              ),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColorsDark.white),
          color: AppColorsDark.surface,
          onSelected: (value) {
            if (value == 'logout') {
              _showLogoutDialog();
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20.sp),
                      SizedBox(width: 12.w),
                      const Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        size: 20.sp,
                        color: AppColorsDark.error,
                      ),
                      SizedBox(width: 12.w),
                      const Text(
                        'Logout',
                        style: TextStyle(color: AppColorsDark.error),
                      ),
                    ],
                  ),
                ),
              ],
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  // ✅ WELCOME BANNER WITH INSIGHTS
  Widget _buildWelcomeBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColorsDark.primaryDark, AppColorsDark.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColorsDark.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🚀 Platform Overview',
                    style: AppTextStyles.titleLarge().copyWith(
                      color: AppColorsDark.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Everything running smoothly',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColorsDark.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.trending_up,
                color: AppColorsDark.white,
                size: 32.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ENHANCED STATS GRID
  Widget _buildEnhancedStatsGrid() {
    final categoriesState = ref.watch(categoriesProvider);
    final storesState = ref.watch(storesProvider);
    final productsState = ref.watch(productsProvider);

    int totalCategories = 0;
    int totalStores = 0;
    int pendingStores = 0;
    int totalProducts = 0;
    int activeStores = 0;

    if (categoriesState is CategoriesLoaded) {
      totalCategories = categoriesState.categories.length;
    }

    if (storesState is StoresLoaded) {
      totalStores = storesState.stores.length;
      pendingStores =
          storesState.stores.where((store) => !store.isApproved).length;
      activeStores = storesState.stores.where((store) => store.isActive).length;
    }

    if (productsState is ProductsLoaded) {
      totalProducts = productsState.products.length;
    }

    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 16.w,
          childAspectRatio: 1.3,
        ),
        delegate: SliverChildListDelegate([
          _buildEnhancedStatCard(
            title: 'Categories',
            value: '$totalCategories',
            icon: Icons.category_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            trend: '+0%',
            trendUp: true,
          ),
          _buildEnhancedStatCard(
            title: 'Total Stores',
            value: '$totalStores',
            icon: Icons.store_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            subtitle: '$activeStores active',
            badge: pendingStores > 0 ? '$pendingStores' : null,
            badgeLabel: 'Pending',
          ),
          _buildEnhancedStatCard(
            title: 'Products',
            value: '$totalProducts',
            icon: Icons.inventory_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            trend: '+0%',
            trendUp: true,
          ),
          _buildEnhancedStatCard(
            title: 'Revenue',
            value: 'PKR 0',
            icon: Icons.attach_money_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFfa709a), Color(0xFFfee140)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            subtitle: 'Coming Soon',
          ),
        ]),
      ),
    );
  }

  Widget _buildEnhancedStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    String? subtitle,
    String? badge,
    String? badgeLabel,
    String? trend,
    bool trendUp = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            right: -20.w,
            top: -20.h,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: AppColorsDark.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColorsDark.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        icon,
                        color: AppColorsDark.white,
                        size: 24.sp,
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorsDark.error,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          badge,
                          style: AppTextStyles.labelSmall().copyWith(
                            color: AppColorsDark.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: AppTextStyles.headlineLarge().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle ?? title,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trend != null) ...[
                      SizedBox(width: 4.w),
                      Icon(
                        trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                        color: AppColorsDark.white,
                        size: 12.sp,
                      ),
                      Text(
                        trend,
                        style: AppTextStyles.labelSmall().copyWith(
                          color: AppColorsDark.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ENHANCED QUICK ACTIONS
  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    gradient: AppColorsDark.primaryGradient,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Quick Actions',
                  style: AppTextStyles.titleLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 1.8,
              children: [
                _buildActionCard(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  color: const Color(0xFF667eea),
                  onTap: () => _showAddCategoryDialog(),
                ),
                _buildActionCard(
                  icon: Icons.store_rounded,
                  label: 'Add Store',
                  color: const Color(0xFF56ab2f),
                  onTap: () => _showAddStoreDialog(),
                ),
                _buildActionCard(
                  icon: Icons.inventory_rounded,
                  label: 'Add Product',
                  color: const Color(0xFFf093fb),
                  onTap: () => _showAddProductDialog(),
                ),
                _buildActionCard(
                  icon: Icons.people_rounded,
                  label: 'View Users',
                  color: const Color(0xFF4facfe),
                  onTap: () {
                    context.push('/admin/users');
                  },
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
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (keep existing _buildPendingApprovals and _buildRecentActivity methods)
  // Just rename _buildRecentStores to _buildRecentActivity

  // ✅ DIALOG METHODS
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => const CategoryManagementDialog(),
    );
  }

  void _showAddStoreDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEditStoreDialog(),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEditProductDialog(),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Logout',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  Widget _buildPendingApprovals(BuildContext context) {
    final storesState = ref.watch(storesProvider);

    if (storesState is! StoresLoaded) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final pendingStores =
        storesState.stores.where((store) => !store.isApproved).take(3).toList();

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
            ...pendingStores.map(
              (store) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _buildApprovalCard(
                  name: store.name,
                  type: store.type,
                  city: store.city,
                  onApprove: () async {
                    await ref
                        .read(storesProvider.notifier)
                        .approveStore(
                          store.id,
                          'admin-id', // TODO: Get from auth provider
                        );
                    _loadDashboardData();
                  },
                  onReject: () async {
                    _showRejectDialog(context, store.id);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final storesState = ref.watch(storesProvider);

    if (storesState is! StoresLoaded) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final recentStores =
        storesState.stores.where((store) => store.isApproved).take(5).toList();

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
            ...recentStores.map(
              (store) => Padding(
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
              ),
            ),
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
            child: Icon(Icons.store, color: AppColorsDark.white, size: 24.sp),
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

  void _showRejectDialog(BuildContext context, String storeId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                  await ref
                      .read(storesProvider.notifier)
                      .rejectStore(
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
                          color:
                              isActive
                                  ? AppColorsDark.success.withOpacity(0.2)
                                  : AppColorsDark.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: AppTextStyles.labelSmall().copyWith(
                            color:
                                isActive
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
}
