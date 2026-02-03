// lib/features/admin/presentation/screens/restaurants/restaurant_management_screen.dart

import 'package:abw_app/features/admin/presentation/screens/restaurants/widgets/add_edit_store_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../stores/presentation/providers/stores_provider.dart';
import '../../../../stores/data/models/store_model.dart';
import 'widgets/add_store_dialog.dart';
import 'widgets/store_details_dialog.dart';

class RestaurantManagementScreen extends ConsumerStatefulWidget {
  const RestaurantManagementScreen({super.key});

  @override
  ConsumerState<RestaurantManagementScreen> createState() =>
      _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState
    extends ConsumerState<RestaurantManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStores();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    await ref.read(storesProvider.notifier).getAllStores();
  }

  @override
  Widget build(BuildContext context) {
    final storesState = ref.watch(storesProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        elevation: 0,
        title: Text(
          'Store Management',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: AppColorsDark.primary,
              size: 28.sp,
            ),
            onPressed: () => _showAddStoreDialog(),
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100.h),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search stores...',
                    hintStyle: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColorsDark.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppColorsDark.textSecondary,
                            ),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColorsDark.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              SizedBox(height: 12.h),
              
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColorsDark.primary,
                indicatorWeight: 3,
                labelColor: AppColorsDark.primary,
                unselectedLabelColor: AppColorsDark.textSecondary,
                labelStyle: AppTextStyles.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Active'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: storesState is StoresLoading
          ? _buildLoadingState()
          : storesState is StoresError
              ? _buildErrorState(storesState.error)
              : storesState is StoresLoaded
                  ? _buildStoresList(storesState.stores)
                  : _buildEmptyState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColorsDark.primary,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading stores...',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppColorsDark.error,
          ),
          SizedBox(height: 16.h),
          Text(
            'Error loading stores',
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
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadStores,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 80.sp,
            color: AppColorsDark.textTertiary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No stores yet',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add your first store to get started',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _showAddStoreDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Store'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresList(List<StoreModel> allStores) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildStoresTab(allStores),
        _buildStoresTab(
          allStores.where((s) => !s.isApproved).toList(),
        ),
        _buildStoresTab(
          allStores.where((s) => s.isApproved && s.isActive).toList(),
        ),
      ],
    );
  }

  Widget _buildStoresTab(List<StoreModel> stores) {
    // Filter by search query
    final filteredStores = stores.where((store) {
      if (_searchQuery.isEmpty) return true;
      return store.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          store.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          store.type.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredStores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: AppColorsDark.textTertiary,
            ),
            SizedBox(height: 16.h),
            Text(
              _searchQuery.isEmpty ? 'No stores in this tab' : 'No results found',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStores,
      color: AppColorsDark.primary,
      backgroundColor: AppColorsDark.surface,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredStores.length,
        itemBuilder: (context, index) {
          final store = filteredStores[index];
          return _buildStoreCard(store);
        },
      ),
    );
  }

  Widget _buildStoreCard(StoreModel store) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showStoreDetails(store),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColorsDark.cardBackground,
                AppColorsDark.surfaceVariant,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: store.isApproved
                  ? AppColorsDark.border
                  : AppColorsDark.warning.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Store Icon/Image
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      gradient: AppColorsDark.primaryGradient,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.store,
                      color: AppColorsDark.white,
                      size: 30.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  // Store Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                store.name,
                                style: AppTextStyles.titleMedium().copyWith(
                                  color: AppColorsDark.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Status Badge
                            _buildStatusBadge(store),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${store.type} • ${store.city}',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Stats Row
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.star,
                    label: store.rating.toStringAsFixed(1),
                    color: AppColorsDark.warning,
                  ),
                  SizedBox(width: 8.w),
                  _buildStatChip(
                    icon: Icons.shopping_bag,
                    label: '${store.totalOrders}',
                    color: AppColorsDark.info,
                  ),
                  SizedBox(width: 8.w),
                  _buildStatChip(
                    icon: Icons.rate_review,
                    label: '${store.totalReviews}',
                    color: AppColorsDark.accent,
                  ),
                  const Spacer(),
                  
                  // Action Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColorsDark.textSecondary,
                    ),
                    color: AppColorsDark.surface,
                    onSelected: (value) => _handleStoreAction(value, store),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20.sp),
                            SizedBox(width: 8.w),
                            const Text('View Details'),
                          ],
                        ),
                      ),
                      if (!store.isApproved)
                        PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 20.sp,
                                color: AppColorsDark.success,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Approve',
                                style: TextStyle(
                                  color: AppColorsDark.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!store.isApproved)
                        PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel,
                                size: 20.sp,
                                color: AppColorsDark.error,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Reject',
                                style: TextStyle(
                                  color: AppColorsDark.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              store.isActive
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(store.isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 20.sp,
                              color: AppColorsDark.error,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColorsDark.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Pending Approval Warning
              if (!store.isApproved) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColorsDark.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColorsDark.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending,
                        color: AppColorsDark.warning,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Pending approval - Review and approve/reject',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(StoreModel store) {
    Color color;
    String text;
    IconData icon;

    if (!store.isApproved) {
      color = AppColorsDark.warning;
      text = 'Pending';
      icon = Icons.pending;
    } else if (!store.isActive) {
      color = AppColorsDark.error;
      text = 'Inactive';
      icon = Icons.visibility_off;
    } else {
      color = AppColorsDark.success;
      text = 'Active';
      icon = Icons.check_circle;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppTextStyles.labelSmall().copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.labelSmall().copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Action handlers
  void _handleStoreAction(String action, StoreModel store) async {
    switch (action) {
      case 'view':
        _showStoreDetails(store);
        break;
      case 'approve':
        await _approveStore(store);
        break;
      case 'reject':
        _showRejectDialog(store);
        break;
      case 'toggle':
        await _toggleStoreStatus(store);
        break;
      case 'delete':
        _showDeleteDialog(store);
        break;
    }
  }

  Future<void> _approveStore(StoreModel store) async {
    final success = await ref.read(storesProvider.notifier).approveStore(
          store.id,
          'admin-id', // TODO: Get from auth provider
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${store.name} approved successfully'),
          backgroundColor: AppColorsDark.success,
        ),
      );
    }
  }

  Future<void> _toggleStoreStatus(StoreModel store) async {
    final success = await ref.read(storesProvider.notifier).toggleStoreStatus(
          store.id,
          !store.isActive,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${store.name} ${!store.isActive ? 'activated' : 'deactivated'}',
          ),
          backgroundColor: AppColorsDark.info,
        ),
      );
    }
  }

  void _showStoreDetails(StoreModel store) {
    showDialog(
      context: context,
      builder: (context) => StoreDetailsDialog(store: store),
    );
  }

 void _showAddStoreDialog() {
  showDialog(
    context: context,
    builder: (context) => const AddEditStoreDialog(),
  );
}

  void _showRejectDialog(StoreModel store) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Store: ${store.name}',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
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
          ],
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
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: AppColorsDark.error,
                  ),
                );
                return;
              }

              await ref.read(storesProvider.notifier).rejectStore(
                    store.id,
                    'admin-id', // TODO: Get from auth provider
                    reasonController.text,
                  );

              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${store.name} rejected'),
                    backgroundColor: AppColorsDark.error,
                  ),
                );
              }
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

  void _showDeleteDialog(StoreModel store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Delete Store',
          style: AppTextStyles.titleMedium().copyWith(
            color: AppColorsDark.error,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${store.name}"? This action cannot be undone.',
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textSecondary,
          ),
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
              await ref.read(storesProvider.notifier).deleteStore(store.id);
              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${store.name} deleted'),
                    backgroundColor: AppColorsDark.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDark.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}