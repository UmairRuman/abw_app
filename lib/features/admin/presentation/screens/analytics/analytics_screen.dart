// lib/features/admin/presentation/screens/analytics/analytics_screen.dart

import 'package:abw_app/features/products/data/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'today'; // today, week, month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(),
            SizedBox(height: 20.h),

            // Overview Cards
            _buildOverviewCards(),
            SizedBox(height: 20.h),

            // Revenue by Category
            _buildRevenueByCategory(),
            SizedBox(height: 20.h),

            // Top Selling Products
            _buildTopSellingProducts(),
            SizedBox(height: 20.h),

            // Orders Timeline
            _buildOrdersTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColorsDark.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _periodButton('Today', 'today'),
          _periodButton('Week', 'week'),
          _periodButton('Month', 'month'),
        ],
      ),
    );
  }

  Widget _periodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColorsDark.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium().copyWith(
              color:
                  isSelected
                      ? AppColorsDark.white
                      : AppColorsDark.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppColorsDark.primary),
          );
        }

        final orders = snapshot.data!.docs;
        final totalOrders = orders.length;
        final totalRevenue = orders.fold<double>(
          0,
          (sum, doc) =>
              sum +
              ((doc.data() as Map<String, dynamic>)['total'] as num).toDouble(),
        );
        final completedOrders =
            orders
                .where(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['status'] ==
                      'delivered',
                )
                .length;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Orders',
                    value: totalOrders.toString(),
                    icon: Icons.receipt_long,
                    color: AppColorsDark.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatCard(
                    title: 'Completed',
                    value: completedOrders.toString(),
                    icon: Icons.check_circle,
                    color: AppColorsDark.success,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildStatCard(
              title: 'Total Revenue',
              value: 'PKR ${totalRevenue.toInt()}',
              icon: Icons.monetization_on,
              color: AppColorsDark.warning,
              fullWidth: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: AppTextStyles.titleLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByCategory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        // Calculate revenue by category
        final Map<String, double> categoryRevenue = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final items = data['items'] as List? ?? [];

          for (var item in items) {
            final categoryName = item['categoryName'] as String? ?? 'Unknown';
            final total = (item['total'] as num).toDouble();
            categoryRevenue[categoryName] =
                (categoryRevenue[categoryName] ?? 0) + total;
          }
        }

        if (categoryRevenue.isEmpty) {
          return _buildEmptyCard('No revenue data');
        }

        // Sort by revenue
        final sorted =
            categoryRevenue.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColorsDark.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColorsDark.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue by Category',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              ...sorted.take(5).map((entry) {
                final percentage = (entry.value / sorted.first.value * 100);
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'PKR ${entry.value.toInt()}',
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColorsDark.surfaceVariant,
                          color: AppColorsDark.primary,
                          minHeight: 8.h,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSellingProducts() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        // Count product quantities
        final Map<String, Map<String, dynamic>> productData = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final items = data['items'] as List? ?? [];

          for (var item in items) {
            final productId = item['productId'] as String? ?? '';
            final productName = item['productName'] as String? ?? 'Unknown';
            final quantity = item['quantity'] as int? ?? 0;
            final total = (item['total'] as num).toDouble();

            if (productData.containsKey(productId)) {
              productData[productId]!['quantity'] += quantity;
              productData[productId]!['revenue'] += total;
            } else {
              productData[productId] = {
                'name': productName,
                'quantity': quantity,
                'revenue': total,
              };
            }
          }
        }

        if (productData.isEmpty) {
          return _buildEmptyCard('No product data');
        }

        // Sort by quantity
        final sorted =
            productData.entries.toList()..sort(
              (a, b) => (b.value['quantity'] as int).compareTo(
                a.value['quantity'] as int,
              ),
            );

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColorsDark.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColorsDark.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Selling Products',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              ...sorted.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final productEntry = entry.value;
                final productData =
                    productEntry.value; // This is Map<String, dynamic>

                return _buildProductRankItem(
                  rank: index + 1,
                  name: productData['name'] as String, // ✅ Access map keys
                  quantity: productData['quantity'] as int, // ✅ Access map keys
                  revenue:
                      productData['revenue'] as double, // ✅ Access map keys
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductRankItem({
    required int rank,
    required String name,
    required int quantity,
    required double revenue,
  }) {
    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = Color(0xFFFFD700); // Gold
        break;
      case 2:
        rankColor = Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        rankColor = Color(0xFFCD7F32); // Bronze
        break;
      default:
        rankColor = AppColorsDark.textTertiary;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsDark.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTextStyles.labelMedium().copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '$quantity sold • PKR ${revenue.toInt()}',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTimeline() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        // Group orders by date
        final Map<String, int> ordersByDate = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          final dateKey = DateFormat('MMM d').format(createdAt);
          ordersByDate[dateKey] = (ordersByDate[dateKey] ?? 0) + 1;
        }

        if (ordersByDate.isEmpty) {
          return _buildEmptyCard('No orders data');
        }

        final maxOrders = ordersByDate.values.reduce((a, b) => a > b ? a : b);

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColorsDark.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColorsDark.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders Timeline',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              ...ordersByDate.entries.map((entry) {
                final percentage = entry.value / maxOrders;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60.w,
                        child: Text(
                          entry.key,
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: AppColorsDark.surfaceVariant,
                            color: AppColorsDark.success,
                            minHeight: 24.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 30.w,
                        child: Text(
                          entry.value.toString(),
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textSecondary,
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
