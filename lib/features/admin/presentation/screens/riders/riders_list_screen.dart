// lib/features/admin/presentation/screens/riders/riders_list_screen.dart
// REPLACE ENTIRE FILE:

import 'dart:developer';

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
    _tabController = TabController(length: 2, vsync: this); // ✅ ONLY 2 TABS
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

              // Tab Bar - ✅ ONLY 2 TABS
              TabBar(
                controller: _tabController,
                indicatorColor: AppColorsDark.primary,
                labelColor: AppColorsDark.primary,
                unselectedLabelColor: AppColorsDark.textSecondary,
                labelStyle: AppTextStyles.labelMedium().copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Pending Approvals'),
                  Tab(text: 'Active Riders'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingRequestsList(), // ✅ From rider_requests collection
          _buildActiveRidersList(), // ✅ From users collection
        ],
      ),
    );
  }

  // ✅ NEW: BUILD PENDING REQUESTS FROM rider_requests COLLECTION
  Widget _buildPendingRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('rider_requests')
              .where('status', isEqualTo: 'pending')
              // ✅ Removed .orderBy() — sort client-side instead
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColorsDark.primary),
          );
        }

        if (snapshot.hasError) {
          // ✅ Now you'll actually see the real error if something goes wrong
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.error,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('pending');
        }

        // ✅ Sort client-side by requestedAt descending
        final requests = snapshot.data!.docs;
        requests.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['requestedAt'] as Timestamp?;
          final bTime = bData['requestedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // descending
        });

        final filteredRequests =
            _searchQuery.isEmpty
                ? requests
                : requests.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['riderName'] as String? ?? '').toLowerCase();
                  final phone =
                      (data['riderPhone'] as String? ?? '').toLowerCase();
                  final vehicle =
                      (data['vehicleNumber'] as String? ?? '').toLowerCase();
                  return name.contains(_searchQuery) ||
                      phone.contains(_searchQuery) ||
                      vehicle.contains(_searchQuery);
                }).toList();

        if (filteredRequests.isEmpty) return _buildSearchEmptyState();

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final doc = filteredRequests[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPendingRequestCard(doc.id, data);
          },
        );
      },
    );
  }

  // ✅ BUILD ACTIVE RIDERS FROM users COLLECTION
  Widget _buildActiveRidersList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'rider')
              .where('isApproved', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColorsDark.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading riders: ${snapshot.error}',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.error,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('active');
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
          return _buildSearchEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: filteredRiders.length,
          itemBuilder: (context, index) {
            return _buildActiveRiderCard(filteredRiders[index]);
          },
        );
      },
    );
  }

  // ✅ PENDING REQUEST CARD
  Widget _buildPendingRequestCard(String requestId, Map<String, dynamic> data) {
    final name = data['riderName'] as String? ?? 'Unknown';
    final phone = data['riderPhone'] as String? ?? '';
    final email = data['riderEmail'] as String? ?? '';
    final vehicleType = data['vehicleType'] as String? ?? '';
    final vehicleNumber = data['vehicleNumber'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColorsDark.warning.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.warning.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColorsDark.warning,
                      AppColorsDark.warning.withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
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
                      name,
                      style: AppTextStyles.titleSmall().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      phone,
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      email,
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Pending Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColorsDark.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'PENDING',
                  style: AppTextStyles.labelSmall().copyWith(
                    color: AppColorsDark.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          const Divider(color: AppColorsDark.border),
          SizedBox(height: 12.h),

          // Vehicle Info
          Row(
            children: [
              Icon(
                Icons.delivery_dining,
                size: 16.sp,
                color: AppColorsDark.textTertiary,
              ),
              SizedBox(width: 8.w),
              Text(
                '$vehicleType • $vehicleNumber',
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveRequest(requestId, data),
                  icon: Icon(Icons.check, size: 18.sp),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsDark.success,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectRequest(requestId),
                  icon: Icon(Icons.close, size: 18.sp),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColorsDark.error,
                    side: const BorderSide(color: AppColorsDark.error),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ ACTIVE RIDER CARD
  Widget _buildActiveRiderCard(RiderModel rider) {
    return InkWell(
      onTap: () => context.push('/admin/riders/${rider.id}'),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColorsDark.border),
          boxShadow: const [
            BoxShadow(
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

            // Status & Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(rider),
                SizedBox(height: 8.h),
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

  // ✅ APPROVE REQUEST
  Future<void> _approveRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: const Text('Approve Rider?'),
            content: Text('Approve ${data['riderName']} as a rider?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.success,
                ),
                child: const Text('Approve'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final riderId = data['riderId'] as String;
      log('🔄 Approving rider: $riderId');

      final approvalData = {
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final fullRiderData = {
        'id': riderId,
        'email': data['riderEmail'] ?? '',
        'name': data['riderName'] ?? '',
        'phone': data['riderPhone'] ?? '',
        'vehicleType': data['vehicleType'] ?? '',
        'vehicleNumber': data['vehicleNumber'] ?? '',
        'licenseNumber': data['licenseNumber'],
        'role': 'rider',
        'isActive': true,
        'isAvailable': false,
        'isPhoneVerified': false,
        'rating': 0.0,
        'totalDeliveries': 0,
        'totalEarnings': 0.0,
        'status': 'offline',
        'currentOrderId': null,
        'profileImage': null,
        ...approvalData, // ✅ includes isApproved: true
      };

      // ✅ STEP 1: UPDATE `riders` COLLECTION (rider listens here)
      log('🔄 Updating riders collection...');
      await FirebaseFirestore.instance
          .collection('riders')
          .doc(riderId)
          .set(fullRiderData, SetOptions(merge: true));
      log('✅ riders collection updated');

      // ✅ STEP 2: UPDATE `users` COLLECTION (auth reads here)
      log('🔄 Updating users collection...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(riderId)
          .set(fullRiderData, SetOptions(merge: true));
      log('✅ users collection updated');

      // ✅ STEP 3: UPDATE rider_requests STATUS
      log('🔄 Updating rider_requests...');
      await FirebaseFirestore.instance
          .collection('rider_requests')
          .doc(requestId)
          .update({
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
          });
      log('✅ rider_requests updated');

      // ✅ VERIFY
      final verifyDoc =
          await FirebaseFirestore.instance
              .collection('riders')
              .doc(riderId)
              .get();
      log('🔍 riders.isApproved: ${verifyDoc.data()?['isApproved']}');

      final verifyDoc2 =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(riderId)
              .get();
      log('🔍 users.isApproved: ${verifyDoc2.data()?['isApproved']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${data['riderName']} approved!'),
            backgroundColor: AppColorsDark.success,
          ),
        );
      }
    } catch (e) {
      log('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  // ✅ REJECT REQUEST
  Future<void> _rejectRequest(String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: const Text('Reject Rider?'),
            content: const Text(
              'This will delete the rider request permanently.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('rider_requests')
          .doc(requestId)
          .update({
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'pending'
                ? Icons.check_circle_outline
                : Icons.delivery_dining,
            size: 64.sp,
            color: AppColorsDark.textTertiary,
          ),
          SizedBox(height: 16.h),
          Text(
            type == 'pending' ? 'No pending requests' : 'No active riders yet',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState() {
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
            'No results found',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
