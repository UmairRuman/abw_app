// lib/features/admin/presentation/screens/analytics/analytics_screen_simple.dart
// MILESTONE 3 - Admin analytics WITHOUT PDF generation (if packages conflict)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedPeriod = 'daily';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(analyticsProvider.notifier).generateDailyReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Revenue Analytics',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
        actions: [
          // ✅ COPY TO CLIPBOARD instead of PDF
          if (analyticsState is AnalyticsLoaded)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyReportToClipboard(analyticsState.report),
              tooltip: 'Copy Report',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child:
                analyticsState is AnalyticsLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColorsDark.primary,
                      ),
                    )
                    : analyticsState is AnalyticsLoaded
                    ? _buildAnalyticsContent(analyticsState.report)
                    : analyticsState is AnalyticsError
                    ? _buildErrorState(analyticsState.message)
                    : const Center(
                      child: Text('Select a period to view analytics'),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColorsDark.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Period',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildPeriodChip('Today', 'daily'),
              SizedBox(width: 8.w),
              _buildPeriodChip('Last 7 Days', 'weekly'),
              SizedBox(width: 8.w),
              _buildPeriodChip('Custom', 'custom'),
            ],
          ),
          if (_selectedPeriod == 'custom') ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectCustomDate(isStart: true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _customStartDate != null
                          ? DateFormat('MMM d').format(_customStartDate!)
                          : 'Start Date',
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectCustomDate(isStart: false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _customEndDate != null
                          ? DateFormat('MMM d').format(_customEndDate!)
                          : 'End Date',
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed:
                      _customStartDate != null && _customEndDate != null
                          ? _loadCustomReport
                          : null,
                  child: const Text('Go'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = value);
          if (value == 'daily') {
            ref.read(analyticsProvider.notifier).generateDailyReport();
          } else if (value == 'weekly') {
            ref.read(analyticsProvider.notifier).generateWeeklyReport();
          }
        }
      },
      selectedColor: AppColorsDark.primary.withOpacity(0.2),
      checkmarkColor: AppColorsDark.primary,
    );
  }

  Widget _buildAnalyticsContent(RevenueReport report) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(report),
          SizedBox(height: 24.h),
          _buildStoreBreakdown(report),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(RevenueReport report) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Revenue',
                'PKR ${report.totalRevenue.toStringAsFixed(0)}',
                Icons.attach_money,
                AppColorsDark.success,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildSummaryCard(
                'Commission',
                'PKR ${report.totalCommission.toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                AppColorsDark.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Orders',
                '${report.totalOrders}',
                Icons.shopping_cart,
                AppColorsDark.info,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildSummaryCard(
                'Active Stores',
                '${report.storeBreakdown.length}',
                Icons.store,
                AppColorsDark.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(height: 12.h),
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.titleLarge().copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreBreakdown(RevenueReport report) {
    final stores = report.storeBreakdown.values.toList();
    stores.sort((a, b) => b.revenue.compareTo(a.revenue));

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Store Breakdown',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColorsDark.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${stores.length} stores',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...stores.map((store) => _buildStoreRow(store)),
        ],
      ),
    );
  }

  Widget _buildStoreRow(StoreRevenue store) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsDark.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.storeName,
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${store.orderCount} orders',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${store.revenue.toStringAsFixed(0)}',
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Comm: PKR ${store.commission.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColorsDark.error),
          SizedBox(height: 16.h),
          Text(
            message,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _selectCustomDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStartDate = picked;
        } else {
          _customEndDate = picked.add(const Duration(days: 1));
        }
      });
    }
  }

  void _loadCustomReport() {
    if (_customStartDate != null && _customEndDate != null) {
      ref
          .read(analyticsProvider.notifier)
          .generateCustomReport(_customStartDate!, _customEndDate!);
    }
  }

  // ✅ COPY REPORT TO CLIPBOARD (instead of PDF)
  Future<void> _copyReportToClipboard(RevenueReport report) async {
    final dateFormat = DateFormat('MMM d, yyyy');
    final dateRange =
        '${dateFormat.format(report.startDate)} - ${dateFormat.format(report.endDate)}';

    final stores = report.storeBreakdown.values.toList();
    stores.sort((a, b) => b.revenue.compareTo(a.revenue));

    final reportText = StringBuffer();
    reportText.writeln('📊 REVENUE REPORT');
    reportText.writeln('Period: $dateRange');
    reportText.writeln('');
    reportText.writeln('SUMMARY:');
    reportText.writeln(
      '💰 Total Revenue: PKR ${report.totalRevenue.toStringAsFixed(2)}',
    );
    reportText.writeln(
      '💵 Commission Earned: PKR ${report.totalCommission.toStringAsFixed(2)}',
    );
    reportText.writeln('📦 Total Orders: ${report.totalOrders}');
    reportText.writeln('🏪 Active Stores: ${stores.length}');
    reportText.writeln('');
    reportText.writeln('STORE BREAKDOWN:');
    reportText.writeln('─' * 50);

    for (final store in stores) {
      reportText.writeln('');
      reportText.writeln('Store: ${store.storeName}');
      reportText.writeln('  Orders: ${store.orderCount}');
      reportText.writeln('  Revenue: PKR ${store.revenue.toStringAsFixed(2)}');
      reportText.writeln(
        '  Commission: PKR ${store.commission.toStringAsFixed(2)}',
      );
    }

    reportText.writeln('');
    reportText.writeln('─' * 50);
    reportText.writeln(
      'Generated: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}',
    );

    await Clipboard.setData(ClipboardData(text: reportText.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8.w),
              const Text('Report copied to clipboard! ✅'),
            ],
          ),
          backgroundColor: AppColorsDark.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
