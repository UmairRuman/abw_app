// lib/features/admin/presentation/screens/riders/admin_riders_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/data/models/rider_model.dart';
import 'admin_rider_detail_screen.dart';

class AdminRidersListScreen extends StatefulWidget {
  const AdminRidersListScreen({super.key});

  @override
  State<AdminRidersListScreen> createState() => _AdminRidersListScreenState();
}

class _AdminRidersListScreenState extends State<AdminRidersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColorsDark.primary,
          unselectedLabelColor: AppColorsDark.textSecondary,
          indicatorColor: AppColorsDark.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search riders by name or phone...',
                hintStyle: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColorsDark.textSecondary,
                  size: 20.sp,
                ),
                filled: true,
                fillColor: AppColorsDark.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColorsDark.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColorsDark.border),
                ),
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRidersList(filter: 'all'),
                _buildRidersList(filter: 'active'),
                _buildRidersList(filter: 'pending'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRidersList({required String filter}) {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'rider');

    if (filter == 'active') {
      query = query.where('isApproved', isEqualTo: true);
    } else if (filter == 'pending') {
      query = query.where('isApproved', isEqualTo: false);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColorsDark.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delivery_dining,
                  size: 64.sp,
                  color: AppColorsDark.textTertiary,
                ),
                SizedBox(height: 16.h),
                Text(
                  filter == 'pending' ? 'No pending riders' : 'No riders found',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        var riders =
            snapshot.data!.docs.map((doc) {
              return RiderModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              });
            }).toList();

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          riders =
              riders.where((r) {
                return r.name.toLowerCase().contains(_searchQuery) ||
                    r.phone.toLowerCase().contains(_searchQuery) ||
                    r.email.toLowerCase().contains(_searchQuery);
              }).toList();
        }

        if (riders.isEmpty) {
          return Center(
            child: Text(
              'No riders match your search',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: riders.length,
          itemBuilder: (context, index) => _buildRiderTile(riders[index]),
        );
      },
    );
  }

  Widget _buildRiderTile(RiderModel rider) {
    final statusColor =
        rider.status.name == 'available'
            ? AppColorsDark.success
            : rider.status.name == 'busy'
            ? AppColorsDark.warning
            : AppColorsDark.error;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: AppColorsDark.primary.withOpacity(0.2),
              child: Text(
                rider.name.substring(0, 1).toUpperCase(),
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Online status dot
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColorsDark.cardBackground,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                rider.name,
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!rider.isApproved)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColorsDark.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'PENDING',
                  style: AppTextStyles.labelSmall().copyWith(
                    color: AppColorsDark.warning,
                    fontSize: 9.sp,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                _buildMiniStat(
                  Icons.delivery_dining,
                  '${rider.totalDeliveries}',
                  AppColorsDark.primary,
                ),
                SizedBox(width: 12.w),
                _buildMiniStat(
                  Icons.monetization_on,
                  'PKR ${rider.totalCollectedCash.toInt()}',
                  AppColorsDark.warning,
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColorsDark.textTertiary,
          size: 20.sp,
        ),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminRiderDetailScreen(riderId: rider.id),
              ),
            ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: color),
        SizedBox(width: 3.w),
        Text(
          value,
          style: AppTextStyles.labelSmall().copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
