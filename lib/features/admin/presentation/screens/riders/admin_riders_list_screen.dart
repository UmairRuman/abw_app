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
                _buildUsersRidersList(filter: 'all'),
                _buildUsersRidersList(filter: 'active'),
                _buildPendingRequestsList(), // ✅ Separate method for rider_requests
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Pending tab reads from rider_requests collection
  Widget _buildPendingRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('rider_requests')
              .where(
                'status',
                isEqualTo: 'pending',
              ) // ✅ No orderBy = no index needed
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
              'Error: ${snapshot.error}',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.error,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No pending requests');
        }

        // Sort client-side — no composite index needed
        var docs = snapshot.data!.docs;
        docs.sort((a, b) {
          final aTime = (a.data() as Map)['requestedAt'] as Timestamp?;
          final bTime = (b.data() as Map)['requestedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        // Apply search
        if (_searchQuery.isNotEmpty) {
          docs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['riderName'] as String? ?? '').toLowerCase();
                final phone =
                    (data['riderPhone'] as String? ?? '').toLowerCase();
                return name.contains(_searchQuery) ||
                    phone.contains(_searchQuery);
              }).toList();
        }

        if (docs.isEmpty) {
          return _buildEmptyState('No riders match your search');
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildPendingRiderTile(docs[index].id, data);
          },
        );
      },
    );
  }

  // ✅ Tile for rider_requests documents (different fields than RiderModel)
  Widget _buildPendingRiderTile(String requestId, Map<String, dynamic> data) {
    final name = data['riderName'] as String? ?? 'Unknown';
    final phone = data['riderPhone'] as String? ?? '';
    final vehicleType = data['vehicleType'] as String? ?? '';
    final vehicleNumber = data['vehicleNumber'] as String? ?? '';
    final requestedAt = data['requestedAt'] as Timestamp?;
    final timeAgo =
        requestedAt != null
            ? _formatTimeAgo(requestedAt.toDate())
            : 'Unknown time';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColorsDark.warning.withOpacity(0.4)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          radius: 24.r,
          backgroundColor: AppColorsDark.warning.withOpacity(0.2),
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: AppTextStyles.titleSmall().copyWith(
            color: AppColorsDark.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              phone,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '$vehicleType • $vehicleNumber',
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Requested $timeAgo',
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textTertiary,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
        onTap: () => _showApprovalBottomSheet(requestId, data),
      ),
    );
  }

  // ✅ Approval bottom sheet
  void _showApprovalBottomSheet(String requestId, Map<String, dynamic> data) {
    final name = data['riderName'] as String? ?? 'Unknown';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorsDark.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Approve $name?',
                  style: AppTextStyles.titleLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Vehicle: ${data['vehicleType']} • ${data['vehicleNumber']}',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectRequest(requestId);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColorsDark.error,
                          side: const BorderSide(color: AppColorsDark.error),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveRequest(requestId, data);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsDark.success,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  Widget _buildEmptyState(String message) {
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
            message,
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersRidersList({required String filter}) {
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

  Future<void> _approveRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    try {
      final riderId = data['riderId'] as String?;
      if (riderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: riderId missing from request'),
            backgroundColor: AppColorsDark.error,
          ),
        );
        return;
      }

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
        'isApproved': true,
        'isAvailable': false,
        'isPhoneVerified': false,
        'rating': 0.0,
        'totalDeliveries': 0,
        'totalEarnings': 0.0,
        'totalCollectedCash': 0.0,
        'status': 'offline',
        'currentOrderId': null,
        'profileImage': null,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Run all writes in parallel for speed
      await Future.wait([
        // Step 1: Create/update in users collection (auth reads here)
        FirebaseFirestore.instance
            .collection('users')
            .doc(riderId)
            .set(fullRiderData, SetOptions(merge: true)),

        // Step 2: Create/update in riders collection (rider app reads here)
        FirebaseFirestore.instance
            .collection('riders')
            .doc(riderId)
            .set(fullRiderData, SetOptions(merge: true)),

        // Step 3: Mark request as approved
        FirebaseFirestore.instance
            .collection('rider_requests')
            .doc(requestId)
            .update({
              'status': 'approved',
              'approvedAt': FieldValue.serverTimestamp(),
            }),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${data['riderName']} approved successfully!'),
            backgroundColor: AppColorsDark.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Approval failed: $e'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    // Ask for rejection reason
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Reject Rider?',
              style: AppTextStyles.titleLarge().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This rider will be notified of the rejection.',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rejection reason (optional)',
                    hintStyle: AppTextStyles.bodySmall().copyWith(
                      color: AppColorsDark.textTertiary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
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
            'rejectionReason':
                reasonController.text.trim().isEmpty
                    ? 'No reason provided'
                    : reasonController.text.trim(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider request rejected'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Rejection failed: $e'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }
}
