// lib/features/admin/presentation/screens/users/users_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../shared/enums/user_role.dart';
import '../../../../auth/data/models/customer_model.dart';
import '../../../../auth/data/models/rider_model.dart';
import 'providers/users_provider.dart';
import 'widgets/user_details_dialog.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
     await Future.delayed(const Duration(milliseconds: 500)); 
    await Future.wait([
      ref.read(usersProvider.notifier).loadCustomers(),
      ref.read(usersProvider.notifier).loadRiders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        elevation: 0,
        title: Text(
          'Users Management',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                    hintText: 'Search users...',
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
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Customers'),
                        if (usersState is UsersLoaded)
                          Container(
                            margin: EdgeInsets.only(left: 8.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorsDark.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '${usersState.customers.length}',
                              style: AppTextStyles.labelSmall().copyWith(
                                color: AppColorsDark.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Riders'),
                        if (usersState is UsersLoaded)
                          Container(
                            margin: EdgeInsets.only(left: 8.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorsDark.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '${usersState.riders.length}',
                              style: AppTextStyles.labelSmall().copyWith(
                                color: AppColorsDark.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: usersState is UsersLoading
          ? _buildLoadingState()
          : usersState is UsersError
              ? _buildErrorState(usersState.error)
              : usersState is UsersLoaded
                  ? _buildUsersTabs(usersState)
                  : _buildEmptyState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColorsDark.primary),
          SizedBox(height: 16.h),
          Text(
            'Loading users...',
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
            'Error loading users',
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
            onPressed: _loadUsers,
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
            Icons.people_outline,
            size: 80.sp,
            color: AppColorsDark.textTertiary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No users yet',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Users will appear here once they sign up',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTabs(UsersLoaded state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCustomersList(state.customers),
        _buildRidersList(state.riders),
      ],
    );
  }

  Widget _buildCustomersList(List<CustomerModel> customers) {
    final filteredCustomers = customers.where((customer) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return customer.name.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query);
    }).toList();

    if (filteredCustomers.isEmpty) {
      return _buildEmptySearchState('No customers found');
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: AppColorsDark.primary,
      backgroundColor: AppColorsDark.surface,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = filteredCustomers[index];
          return _buildCustomerCard(customer);
        },
      ),
    );
  }

  Widget _buildRidersList(List<RiderModel> riders) {
    final filteredRiders = riders.where((rider) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return rider.name.toLowerCase().contains(query) ||
          rider.email.toLowerCase().contains(query) ||
          (rider.vehicleNumber?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (filteredRiders.isEmpty) {
      return _buildEmptySearchState('No riders found');
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: AppColorsDark.primary,
      backgroundColor: AppColorsDark.surface,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredRiders.length,
        itemBuilder: (context, index) {
          final rider = filteredRiders[index];
          return _buildRiderCard(rider);
        },
      ),
    );
  }

  Widget _buildEmptySearchState(String message) {
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
            message,
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showUserDetails(customer, UserRole.customer),
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
            border: Border.all(color: AppColorsDark.border),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  gradient: AppColorsDark.primaryGradient,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Center(
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name.substring(0, 2).toUpperCase()
                        : 'U',
                    style: AppTextStyles.titleMedium().copyWith(
                      color: AppColorsDark.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: 14.sp,
                          color: AppColorsDark.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            customer.email,
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (customer.phone != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14.sp,
                            color: AppColorsDark.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            customer.phone!,
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Stats Badge
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColorsDark.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_bag,
                      size: 20.sp,
                      color: AppColorsDark.info,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '0', // TODO: Get actual order count
                      style: AppTextStyles.labelMedium().copyWith(
                        color: AppColorsDark.info,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Orders',
                      style: AppTextStyles.labelSmall().copyWith(
                        color: AppColorsDark.textSecondary,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiderCard(RiderModel rider) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showUserDetails(rider, UserRole.rider),
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
            border: Border.all(color: AppColorsDark.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColorsDark.success,
                          AppColorsDark.successLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.delivery_dining,
                        color: AppColorsDark.white,
                        size: 30.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),

                  // Rider Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rider.name,
                                style: AppTextStyles.titleMedium().copyWith(
                                  color: AppColorsDark.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: rider.isApproved
                                    ? AppColorsDark.success.withOpacity(0.2)
                                    : AppColorsDark.warning.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                rider.isApproved ? 'Active' : 'Pending',
                                style: AppTextStyles.labelSmall().copyWith(
                                  color: rider.isApproved
                                      ? AppColorsDark.success
                                      : AppColorsDark.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 14.sp,
                              color: AppColorsDark.textSecondary,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                rider.email,
                                style: AppTextStyles.bodySmall().copyWith(
                                  color: AppColorsDark.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (rider.vehicleType != null || rider.vehicleNumber != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColorsDark.surfaceContainer,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.two_wheeler,
                        size: 20.sp,
                        color: AppColorsDark.textSecondary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${rider.vehicleType ?? 'N/A'} - ${rider.vehicleNumber ?? 'N/A'}',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColorsDark.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              size: 16.sp,
                              color: AppColorsDark.success,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '0', // TODO: Get actual delivery count
                              style: AppTextStyles.labelSmall().copyWith(
                                color: AppColorsDark.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  void _showUserDetails(dynamic user, UserRole role) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(
        user: user,
        role: role,
      ),
    );
  }
}