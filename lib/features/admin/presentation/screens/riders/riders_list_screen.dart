// lib/features/admin/presentation/screens/riders/riders_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/data/models/rider_model.dart';
import '../../../../auth/domain/entities/rider_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RidersListScreen extends ConsumerStatefulWidget {
  const RidersListScreen({super.key});

  @override
  ConsumerState<RidersListScreen> createState() => _RidersListScreenState();
}

class _RidersListScreenState extends ConsumerState<RidersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Rider Management',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(90.h),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: TextField(
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, or vehicle...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColorsDark.textSecondary,
                      size: 20.sp,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),

              // Tab Bar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColorsDark.primary,
                labelColor: AppColorsDark.primary,
                unselectedLabelColor: AppColorsDark.textSecondary,
                labelStyle: AppTextStyles.labelMedium().copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'All Riders'),
                  Tab(text: 'Pending Approval'),
                  Tab(text: 'Active'),
                  Tab(text: 'Offline'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRidersList(filter: 'all'),
          _buildRidersList(filter: 'pending'),
          _buildRidersList(filter: 'active'),
          _buildRidersList(filter: 'offline'),
        ],
      ),
    );
  }

  Widget _buildRidersList({required String filter}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getRidersStream(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColorsDark.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading riders',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.error,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(filter);
        }

        final riders =
            snapshot.data!.docs
                .map(
                  (doc) => RiderModel.fromJson({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  }),
                )
                .toList();

        // Apply search filter
        final filteredRiders =
            _searchQuery.isEmpty
                ? riders
                : riders.where((r) {
                  return r.name.toLowerCase().contains(_searchQuery) ||
                      r.phone.toLowerCase().contains(_searchQuery) ||
                      r.vehicleNumber.toLowerCase().contains(_searchQuery);
                }).toList();

        if (filteredRiders.isEmpty) {
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
                  'No riders found',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: filteredRiders.length,
          itemBuilder: (context, index) {
            return _buildRiderCard(filteredRiders[index]);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getRidersStream(String filter) {
    var query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'rider');

    switch (filter) {
      case 'pending':
        return query
            .where('isApproved', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .snapshots();
      case 'active':
        return query
            .where('isApproved', isEqualTo: true)
            .where('status', isEqualTo: 'available')
            .orderBy('createdAt', descending: true)
            .snapshots();
      case 'offline':
        return query
            .where('isApproved', isEqualTo: true)
            .where('status', isEqualTo: 'offline')
            .orderBy('createdAt', descending: true)
            .snapshots();
      default:
        return query.orderBy('createdAt', descending: true).snapshots();
    }
  }

  Widget _buildRiderCard(RiderModel rider) {
    return InkWell(
      onTap: () => context.push('/admin/riders/${rider.id}'),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color:
                rider.isApproved
                    ? AppColorsDark.border
                    : AppColorsDark.warning.withOpacity(0.3),
          ),
          boxShadow: [
            const BoxShadow(
              color: AppColorsDark.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56.w,
              height: 56.w,
              decoration: const BoxDecoration(
                gradient: AppColorsDark.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  rider.name.substring(0, 1).toUpperCase(),
                  style: AppTextStyles.titleLarge().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.name,
                    style: AppTextStyles.titleSmall().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    rider.phone,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        size: 14.sp,
                        color: AppColorsDark.textTertiary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${rider.vehicleType} • ${rider.vehicleNumber}',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(rider),
                SizedBox(height: 8.h),
                if (rider.isApproved)
                  Text(
                    '${rider.totalDeliveries} deliveries',
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RiderModel rider) {
    if (!rider.isApproved) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColorsDark.warning.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          'Pending',
          style: AppTextStyles.labelSmall().copyWith(
            color: AppColorsDark.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Color color;
    String text;
    switch (rider.status) {
      case RiderStatus.available:
        color = AppColorsDark.success;
        text = 'Online';
        break;
      case RiderStatus.busy:
        color = AppColorsDark.primary;
        text = 'Busy';
        break;
      case RiderStatus.offline:
        color = AppColorsDark.textTertiary;
        text = 'Offline';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
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

  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;

    switch (filter) {
      case 'pending':
        message = 'No pending rider approvals';
        icon = Icons.check_circle_outline;
        break;
      case 'active':
        message = 'No riders online';
        icon = Icons.delivery_dining;
        break;
      case 'offline':
        message = 'No offline riders';
        icon = Icons.offline_bolt;
        break;
      default:
        message = 'No riders yet';
        icon = Icons.person_outline;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.sp, color: AppColorsDark.textTertiary),
          SizedBox(height: 16.h),
          Text(
            message,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
