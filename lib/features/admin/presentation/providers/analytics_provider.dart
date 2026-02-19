// lib/features/admin/presentation/providers/analytics_provider.dart
// MILESTONE 3 - Admin analytics with reports and commission tracking

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../../../orders/data/models/order_model.dart';
import '../../../orders/domain/entities/order_entity.dart';

// Models
class RevenueReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final double totalCommission;
  final int totalOrders;
  final Map<String, StoreRevenue> storeBreakdown;

  RevenueReport({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalCommission,
    required this.totalOrders,
    required this.storeBreakdown,
  });
}

class StoreRevenue {
  final String storeId;
  final String storeName;
  final int orderCount;
  final double revenue;
  final double commission;

  StoreRevenue({
    required this.storeId,
    required this.storeName,
    required this.orderCount,
    required this.revenue,
    required this.commission,
  });
}

// States
abstract class AnalyticsState {}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final RevenueReport report;
  AnalyticsLoaded(this.report);
}

class AnalyticsError extends AnalyticsState {
  final String message;
  AnalyticsError(this.message);
}

// Notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(AnalyticsInitial());

  final _firestore = FirebaseFirestore.instance;

  /// Generate daily report (today)
  Future<void> generateDailyReport() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    await _generateReport(startOfDay, endOfDay);
  }

  /// Generate weekly report (last 7 days)
  Future<void> generateWeeklyReport() async {
    final now = DateTime.now();
    final endDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final startDate = endDate.subtract(const Duration(days: 7));

    await _generateReport(startDate, endDate);
  }

  /// Generate custom date range report
  Future<void> generateCustomReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    await _generateReport(startDate, endDate);
  }

  /// Generate report for date range
  Future<void> _generateReport(DateTime startDate, DateTime endDate) async {
    state = AnalyticsLoading();

    try {
      dev.log(
        '📊 Generating report: ${startDate.toString()} - ${endDate.toString()}',
      );

      // Query orders in date range
      final ordersSnapshot =
          await _firestore
              .collection('orders')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
              .where(
                'status',
                whereIn: [
                  OrderStatus.delivered.name,
                  OrderStatus.outForDelivery.name,
                  OrderStatus.confirmed.name,
                ],
              )
              .get();

      if (ordersSnapshot.docs.isEmpty) {
        dev.log('⚠️ No orders found in date range');
        state = AnalyticsError('No orders found in selected date range');
        return;
      }

      // Parse orders
      final orders =
          ordersSnapshot.docs.map((doc) {
            return OrderModel.fromJson({'id': doc.id, ...doc.data()});
          }).toList();

      dev.log('✅ Found ${orders.length} orders');

      // Calculate totals
      double totalRevenue = 0;
      double totalCommission = 0;
      final storeData = <String, StoreRevenue>{};

      for (final order in orders) {
        totalRevenue += order.total;
        totalCommission += order.storeCommission ?? 0.0;

        // Store-wise breakdown
        final storeId = order.storeId;
        if (storeData.containsKey(storeId)) {
          final existing = storeData[storeId]!;
          storeData[storeId] = StoreRevenue(
            storeId: storeId,
            storeName: existing.storeName,
            orderCount: existing.orderCount + 1,
            revenue: existing.revenue + order.total,
            commission: existing.commission + (order.storeCommission ?? 0.0),
          );
        } else {
          storeData[storeId] = StoreRevenue(
            storeId: storeId,
            storeName: order.storeName,
            orderCount: 1,
            revenue: order.total,
            commission: order.storeCommission ?? 0.0,
          );
        }
      }

      // Create report
      final report = RevenueReport(
        startDate: startDate,
        endDate: endDate,
        totalRevenue: totalRevenue,
        totalCommission: totalCommission,
        totalOrders: orders.length,
        storeBreakdown: storeData,
      );

      dev.log('✅ Report generated:');
      dev.log('   Total Revenue: PKR ${totalRevenue.toStringAsFixed(2)}');
      dev.log('   Total Commission: PKR ${totalCommission.toStringAsFixed(2)}');
      dev.log('   Total Orders: ${orders.length}');
      dev.log('   Stores: ${storeData.length}');

      state = AnalyticsLoaded(report);
    } catch (e) {
      dev.log('❌ Error generating report: $e');
      state = AnalyticsError(e.toString());
    }
  }

  /// Get top performing stores
  List<StoreRevenue> getTopStores(int limit) {
    if (state is AnalyticsLoaded) {
      final report = (state as AnalyticsLoaded).report;
      final stores = report.storeBreakdown.values.toList();

      // Sort by revenue (descending)
      stores.sort((a, b) => b.revenue.compareTo(a.revenue));

      return stores.take(limit).toList();
    }
    return [];
  }

  /// Get total commission earned
  double getTotalCommission() {
    if (state is AnalyticsLoaded) {
      return (state as AnalyticsLoaded).report.totalCommission;
    }
    return 0.0;
  }

  /// Get average order value
  double getAverageOrderValue() {
    if (state is AnalyticsLoaded) {
      final report = (state as AnalyticsLoaded).report;
      if (report.totalOrders == 0) return 0.0;
      return report.totalRevenue / report.totalOrders;
    }
    return 0.0;
  }

  /// Reset state
  void reset() {
    state = AnalyticsInitial();
  }
}

// Provider
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
      (ref) => AnalyticsNotifier(),
    );
