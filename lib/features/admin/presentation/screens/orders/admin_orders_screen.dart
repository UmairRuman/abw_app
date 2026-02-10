// lib/features/admin/presentation/screens/orders/admin_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../orders/presentation/providers/orders_provider.dart';
import '../../../../orders/data/models/order_model.dart';
import '../../../../orders/domain/entities/order_entity.dart';
import 'admin_order_details_screen.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final List<String> _tabs = [
    'All',
    'Pending',
    'Confirmed',
    'Preparing',
    'On the Way',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersStream = ref.watch(allOrdersStreamProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Order Management',
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
                    hintText: 'Search by order ID or customer name...',
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
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: ordersStream.when(
        data: (orders) {
          return TabBarView(
            controller: _tabController,
            children:
                _tabs.map((tab) {
                  final filtered = _filterOrders(orders, tab);
                  final searched =
                      _searchQuery.isEmpty
                          ? filtered
                          : filtered.where((o) {
                            return o.id.toLowerCase().contains(_searchQuery) ||
                                o.userName.toLowerCase().contains(
                                  _searchQuery,
                                ) ||
                                o.storeName.toLowerCase().contains(
                                  _searchQuery,
                                );
                          }).toList();

                  return _buildOrdersList(searched);
                }).toList(),
          );
        },
        loading:
            () => Center(
              child: CircularProgressIndicator(color: AppColorsDark.primary),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'Error loading orders',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.error,
                ),
              ),
            ),
      ),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders, String tab) {
    switch (tab) {
      case 'Pending':
        return orders.where((o) => o.status == OrderStatus.pending).toList();
      case 'Confirmed':
        return orders.where((o) => o.status == OrderStatus.confirmed).toList();
      case 'Preparing':
        return orders.where((o) => o.status == OrderStatus.preparing).toList();
      case 'On the Way':
        return orders
            .where((o) => o.status == OrderStatus.outForDelivery)
            .toList();
      case 'Delivered':
        return orders.where((o) => o.status == OrderStatus.delivered).toList();
      case 'Cancelled':
        return orders.where((o) => o.status == OrderStatus.cancelled).toList();
      default:
        return orders;
    }
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64.sp,
              color: AppColorsDark.textTertiary,
            ),
            SizedBox(height: 16.h),
            Text(
              'No orders found',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await Future.delayed(Duration(milliseconds: 500)),
      color: AppColorsDark.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildAdminOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildAdminOrderCard(OrderModel order) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminOrderDetailsScreen(orderId: order.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColorsDark.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _getStatusColor(order.status).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColorsDark.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  // Order ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.id.substring(order.id.length - 8)}',
                          style: AppTextStyles.titleSmall().copyWith(
                            color: AppColorsDark.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          DateFormat('MMM d, h:mm a').format(order.createdAt),
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  _buildStatusBadge(order.status),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Customer & Store
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.person,
                        label: order.userName,
                        color: AppColorsDark.primary,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.store,
                          label: order.storeName,
                          color: AppColorsDark.secondary,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Payment & Total Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Payment Method + Proof indicator
                      Row(
                        children: [
                          _buildPaymentMethodBadge(order.paymentMethod),
                          if (order.paymentProofUrl != null) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColorsDark.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 12.sp,
                                    color: AppColorsDark.success,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Proof',
                                    style: AppTextStyles.labelSmall().copyWith(
                                      color: AppColorsDark.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Total
                      Text(
                        'PKR ${order.total.toInt()}',
                        style: AppTextStyles.titleMedium().copyWith(
                          color: AppColorsDark.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AdminOrderDetailsScreen(
                                      orderId: order.id,
                                    ),
                              ),
                            );
                          },
                          icon: Icon(Icons.visibility, size: 16.sp),
                          label: const Text('View Details'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                      if (order.status == OrderStatus.pending) ...[
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _quickUpdateStatus(
                                  order,
                                  OrderStatus.confirmed,
                                ),
                            icon: Icon(Icons.check, size: 16.sp),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColorsDark.success,
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                            ),
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
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        _getStatusLabel(status),
        style: AppTextStyles.labelSmall().copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBadge(PaymentMethod method) {
    String label;
    Color color;

    switch (method) {
      case PaymentMethod.cod:
        label = 'COD';
        color = AppColorsDark.success;
        break;
      case PaymentMethod.jazzcash:
        label = 'JazzCash';
        color = Color(0xFFFF6B00);
        break;
      case PaymentMethod.easypaisa:
        label = 'EasyPaisa';
        color = Color(0xFF00A651);
        break;
      case PaymentMethod.bankTransfer:
        label = 'Bank';
        color = AppColorsDark.info;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall().copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColorsDark.warning;
      case OrderStatus.confirmed:
        return AppColorsDark.info;
      case OrderStatus.preparing:
        return Color(0xFFFF6B00);
      case OrderStatus.outForDelivery:
        return AppColorsDark.primary;
      case OrderStatus.delivered:
        return AppColorsDark.success;
      case OrderStatus.cancelled:
        return AppColorsDark.error;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Future<void> _quickUpdateStatus(
    OrderModel order,
    OrderStatus newStatus,
  ) async {
    final success = await ref
        .read(ordersProvider.notifier)
        .updateOrderStatus(
          order.id,
          newStatus,
          'Status updated by admin',
          'admin',
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Order confirmed!' : 'Failed to update'),
          backgroundColor:
              success ? AppColorsDark.success : AppColorsDark.error,
        ),
      );
    }
  }
}

// Add to orders_provider.dart:
final allOrdersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.read(ordersProvider.notifier).getAllOrdersStream();
});
