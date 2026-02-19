// lib/features/rider/presentation/screens/orders/rider_order_details_screen.dart
// MILESTONE 3 - Rider order details with map, distance, and customer contact

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as dev;

import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../orders/presentation/providers/orders_provider.dart';
import '../../../../orders/data/models/order_model.dart';
import '../../../../orders/domain/entities/order_entity.dart';

class RiderOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const RiderOrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<RiderOrderDetailsScreen> createState() =>
      _RiderOrderDetailsScreenState();
}

class _RiderOrderDetailsScreenState
    extends ConsumerState<RiderOrderDetailsScreen> {
  bool _isPickingUp = false;
  bool _isDelivering = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).getOrderById(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
      ),
      body:
          ordersState is OrdersLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              )
              : ordersState is OrderSingleLoaded
              ? _buildOrderDetails(ordersState.order)
              : const Center(child: Text('Failed to load order')),
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    final canPickup =
        order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.preparing;
    final canDeliver = order.status == OrderStatus.outForDelivery;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Map with route
                _buildMap(order),

                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      // Distance card
                      _buildDistanceCard(order),
                      SizedBox(height: 16.h),

                      // Store info
                      _buildStoreInfo(order),
                      SizedBox(height: 16.h),

                      // Customer info
                      _buildCustomerInfo(order),
                      SizedBox(height: 16.h),

                      // Order items
                      _buildOrderItems(order),
                      SizedBox(height: 16.h),

                      // Payment info
                      _buildPaymentInfo(order),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom actions
        _buildBottomActions(order, canPickup, canDeliver),
      ],
    );
  }

  Widget _buildMap(OrderModel order) {
    if (order.pickupLatitude == null ||
        order.pickupLongitude == null ||
        order.deliveryLatitude == null ||
        order.deliveryLongitude == null) {
      return Container(
        height: 250.h,
        color: AppColorsDark.surfaceVariant,
        child: Center(
          child: Text(
            'No location data available',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ),
      );
    }

    final pickupPoint = LatLng(order.pickupLatitude!, order.pickupLongitude!);
    final deliveryPoint = LatLng(
      order.deliveryLatitude!,
      order.deliveryLongitude!,
    );

    // Calculate center point
    final centerLat = (order.pickupLatitude! + order.deliveryLatitude!) / 2;
    final centerLng = (order.pickupLongitude! + order.deliveryLongitude!) / 2;

    return SizedBox(
      height: 250.h,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(centerLat, centerLng),
          initialZoom: 12.0,
        ),
        children: [
          // OpenStreetMap tiles
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.abw.app',
          ),

          // Markers
          MarkerLayer(
            markers: [
              // Pickup marker (green)
              Marker(
                point: pickupPoint,
                width: 40.w,
                height: 40.w,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColorsDark.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store,
                    color: AppColorsDark.white,
                    size: 20.sp,
                  ),
                ),
              ),

              // Delivery marker (red)
              Marker(
                point: deliveryPoint,
                width: 40.w,
                height: 40.w,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColorsDark.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppColorsDark.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),

          // Route line
          PolylineLayer(
            polylines: [
              Polyline(
                points: [pickupPoint, deliveryPoint],
                color: AppColorsDark.primary,
                strokeWidth: 3.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard(OrderModel order) {
    final distance = order.distance ?? 0.0;
    final formattedDistance = LocationService.formatDistance(distance);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColorsDark.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Distance',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                formattedDistance,
                style: AppTextStyles.headlineMedium().copyWith(
                  color: AppColorsDark.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Delivery Fee',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'PKR ${order.deliveryFee.toInt()}',
                style: AppTextStyles.titleLarge().copyWith(
                  color: AppColorsDark.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo(OrderModel order) {
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
            children: [
              Icon(Icons.store, color: AppColorsDark.success, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Pickup From',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            order.storeName,
            style: AppTextStyles.bodyLarge().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(OrderModel order) {
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
              Row(
                children: [
                  Icon(Icons.person, color: AppColorsDark.info, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Customer Details',
                    style: AppTextStyles.titleMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Call customer button
              InkWell(
                onTap: () => _callCustomer(order.userPhone),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColorsDark.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.phone,
                    color: AppColorsDark.success,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            order.userName,
            style: AppTextStyles.bodyLarge().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            order.userPhone,
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          const Divider(color: AppColorsDark.border),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.location_on, color: AppColorsDark.error, size: 16.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  order.deliveryAddress.getShortAddress(),
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(OrderModel order) {
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
                'Order Items',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColorsDark.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${order.items.length} items',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...order.items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      item.productName,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(OrderModel order) {
    final isCOD = order.paymentMethod == PaymentMethod.cod;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            isCOD
                ? AppColorsDark.warning.withOpacity(0.1)
                : AppColorsDark.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              isCOD
                  ? AppColorsDark.warning.withOpacity(0.3)
                  : AppColorsDark.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCOD ? Icons.money : Icons.check_circle,
            color: isCOD ? AppColorsDark.warning : AppColorsDark.success,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCOD ? 'Collect Cash' : 'Already Paid',
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isCOD
                      ? 'Collect PKR ${order.total.toInt()} from customer'
                      : 'Payment completed online',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'PKR ${order.total.toInt()}',
            style: AppTextStyles.titleLarge().copyWith(
              color: isCOD ? AppColorsDark.warning : AppColorsDark.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    OrderModel order,
    bool canPickup,
    bool canDeliver,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        color: AppColorsDark.surface,
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.shadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child:
            canPickup
                ? _buildPickupButton(order)
                : canDeliver
                ? _buildDeliverButton(order)
                : _buildStatusInfo(order),
      ),
    );
  }

  Widget _buildPickupButton(OrderModel order) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isPickingUp ? null : () => _confirmPickup(order),
        icon:
            _isPickingUp
                ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColorsDark.white,
                  ),
                )
                : Icon(Icons.check_circle, size: 20.sp),
        label: Text(
          _isPickingUp ? 'Confirming Pickup...' : 'Confirm Pickup',
          style: AppTextStyles.button(),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.success,
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
    );
  }

  Widget _buildDeliverButton(OrderModel order) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isDelivering ? null : () => _confirmDelivery(order),
        icon:
            _isDelivering
                ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColorsDark.white,
                  ),
                )
                : Icon(Icons.delivery_dining, size: 20.sp),
        label: Text(
          _isDelivering ? 'Completing Delivery...' : 'Mark as Delivered',
          style: AppTextStyles.button(),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
    );
  }

  Widget _buildStatusInfo(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsDark.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        'Order status: ${order.status.name}',
        style: AppTextStyles.bodyMedium().copyWith(color: AppColorsDark.info),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone dialer'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmPickup(OrderModel order) async {
    setState(() => _isPickingUp = true);

    try {
      final success = await ref
          .read(ordersProvider.notifier)
          .updateOrderStatus(
            order.id,
            OrderStatus.outForDelivery,
            'I am a rider',
            'rider',
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pickup confirmed!'),
            backgroundColor: AppColorsDark.success,
          ),
        );
        await ref.read(ordersProvider.notifier).getOrderById(order.id);
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
    } finally {
      if (mounted) setState(() => _isPickingUp = false);
    }
  }

  Future<void> _confirmDelivery(OrderModel order) async {
    setState(() => _isDelivering = true);

    try {
      final success = await ref
          .read(ordersProvider.notifier)
          .updateOrderStatus(
            order.id,
            OrderStatus.delivered,
            'I am a rider',
            'rider',
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Delivery completed!'),
            backgroundColor: AppColorsDark.success,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
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
    } finally {
      if (mounted) setState(() => _isDelivering = false);
    }
  }
}
