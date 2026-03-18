// lib/core/widgets/order_map_widget.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/colors/app_colors_dark.dart';
import '../theme/text_styles/app_text_styles.dart';
import '../../features/orders/data/models/order_model.dart';

class OrderMapWidget extends StatefulWidget {
  final OrderModel order;
  final double mapHeight;

  const OrderMapWidget({super.key, required this.order, this.mapHeight = 260});

  @override
  State<OrderMapWidget> createState() => _OrderMapWidgetState();
}

class _OrderMapWidgetState extends State<OrderMapWidget> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  double? _etaMinutes;
  double? _routeDistanceKm;
  final MapController _mapController = MapController();

  // ✅ Resolved coordinates — may be fetched from store if null on order
  double? _pickupLat;
  double? _pickupLng;
  double? _deliveryLat;
  double? _deliveryLng;

  @override
  void initState() {
    super.initState();
    _resolveCoordinatesAndFetchRoute();
  }

  // ── Step 1: Resolve all coordinates ───────────────────────────────────────
  //
  // Handles three cases:
  //   A) New orders  → all 4 top-level coords present on order ✅
  //   B) Old orders  → deliveryLatitude null, but present in deliveryAddress ✅
  //                    (fixed in order_model.fromJson, will be non-null here)
  //   C) Old orders  → pickupLatitude null (store coords never saved)
  //                    → fetch from stores/{storeId} once ✅

  Future<void> _resolveCoordinatesAndFetchRoute() async {
    final order = widget.order;

    // Delivery coords — already resolved by order_model.fromJson fallback
    _deliveryLat = order.deliveryLatitude;
    _deliveryLng = order.deliveryLongitude;

    // Pickup coords — try order first, then fetch from store
    _pickupLat = order.pickupLatitude;
    _pickupLng = order.pickupLongitude;

    if ((_pickupLat == null || _pickupLat == 0.0) && order.storeId.isNotEmpty) {
      // ✅ FIX: Pickup coords missing on old orders — fetch from store document
      try {
        final storeDoc =
            await FirebaseFirestore.instance
                .collection('stores')
                .doc(order.storeId)
                .get();

        if (storeDoc.exists && storeDoc.data() != null) {
          final data = storeDoc.data()!;
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          if (lat != null && lat != 0.0 && lng != null && lng != 0.0) {
            _pickupLat = lat;
            _pickupLng = lng;
          }
        }
      } catch (e) {
        debugPrint('⚠️ OrderMapWidget: could not fetch store coords: $e');
      }
    }

    // Now fetch the route with resolved coords
    await _fetchRoute();
  }

  // ── Step 2: OSRM route fetch ───────────────────────────────────────────────

  Future<void> _fetchRoute() async {
    if (_pickupLat == null ||
        _pickupLng == null ||
        _deliveryLat == null ||
        _deliveryLng == null) {
      if (mounted) setState(() => _isLoadingRoute = false);
      return;
    }

    try {
      final url =
          'http://router.project-osrm.org/route/v1/driving/'
          '$_pickupLng,$_pickupLat;'
          '$_deliveryLng,$_deliveryLat'
          '?overview=full&geometries=geojson';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          final route = routes[0] as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;

          final points =
              coordinates
                  .map(
                    (c) => LatLng(
                      (c[1] as num).toDouble(),
                      (c[0] as num).toDouble(),
                    ),
                  )
                  .toList();

          final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;
          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;

          if (mounted) {
            setState(() {
              _routePoints = points;
              _etaMinutes = durationSeconds / 60;
              _routeDistanceKm = distanceMeters / 1000;
              _isLoadingRoute = false;
            });
          }
          _fitMapToBounds();
          return;
        }
      }
      _fallbackToStraightLine();
    } catch (_) {
      _fallbackToStraightLine();
    }
  }

  void _fallbackToStraightLine() {
    if (_pickupLat == null || _deliveryLat == null) {
      if (mounted) setState(() => _isLoadingRoute = false);
      return;
    }
    if (mounted) {
      setState(() {
        _routePoints = [
          LatLng(_pickupLat!, _pickupLng!),
          LatLng(_deliveryLat!, _deliveryLng!),
        ];
        _routeDistanceKm = (widget.order.distance ?? 0) / 1000;
        _isLoadingRoute = false;
      });
    }
    _fitMapToBounds();
  }

  void _fitMapToBounds() {
    if (_routePoints.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final bounds = LatLngBounds.fromPoints(_routePoints);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(60.w)),
        );
      } catch (_) {}
    });
  }

  // ── Directions ────────────────────────────────────────────────────────────

  Future<void> _openDirections() async {
    if (_deliveryLat == null || _pickupLat == null) return;

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$_pickupLat,$_pickupLng'
      '&destination=$_deliveryLat,$_deliveryLng'
      '&travelmode=driving',
    );

    final osmUrl = Uri.parse(
      'https://www.openstreetmap.org/directions'
      '?engine=fossgis_osrm_car'
      '&route=$_pickupLat,$_pickupLng;$_deliveryLat,$_deliveryLng',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(osmUrl)) {
      await launchUrl(osmUrl, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open maps app'),
          backgroundColor: AppColorsDark.error,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasCoords = _pickupLat != null && _deliveryLat != null;

    // Still loading store coords / route
    if (_isLoadingRoute && !hasCoords) {
      return _buildLoadingCard();
    }

    if (!hasCoords) {
      return _buildNoLocationCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMapTile(),
        SizedBox(height: 12.h),
        _buildAddressCard(),
        SizedBox(height: 12.h),
        _buildDirectionsButton(),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 120.h,
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColorsDark.primary),
      ),
    );
  }

  Widget _buildMapTile() {
    final pickupPoint = LatLng(_pickupLat!, _pickupLng!);
    final deliveryPoint = LatLng(_deliveryLat!, _deliveryLng!);
    final centerLat = (_pickupLat! + _deliveryLat!) / 2;
    final centerLng = (_pickupLng! + _deliveryLng!) / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: widget.mapHeight.h,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(centerLat, centerLng),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.abw.app',
                  maxZoom: 19,
                ),
                if (_routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: AppColorsDark.primary,
                        strokeWidth: 4.0,
                        borderColor: AppColorsDark.primary.withOpacity(0.3),
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pickupPoint,
                      width: 44.w,
                      height: 56.h,
                      alignment: Alignment.topCenter,
                      child: _buildMarker(
                        icon: Icons.store,
                        color: AppColorsDark.success,
                      ),
                    ),
                    Marker(
                      point: deliveryPoint,
                      width: 44.w,
                      height: 56.h,
                      alignment: Alignment.topCenter,
                      child: _buildMarker(
                        icon: Icons.location_on,
                        color: AppColorsDark.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Loading route overlay (coords resolved, route still loading)
            if (_isLoadingRoute)
              Positioned(
                top: 12.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsDark.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12.w,
                          height: 12.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColorsDark.primary,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Loading route...',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ETA + Distance chips
            if (!_isLoadingRoute &&
                (_etaMinutes != null || _routeDistanceKm != null))
              Positioned(
                top: 12.h,
                right: 12.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_routeDistanceKm != null)
                      _buildChip(
                        icon: Icons.route,
                        label:
                            _routeDistanceKm! >= 1
                                ? '${_routeDistanceKm!.toStringAsFixed(1)} km'
                                : '${(_routeDistanceKm! * 1000).toInt()} m',
                        color: AppColorsDark.primary,
                      ),
                    if (_etaMinutes != null) ...[
                      SizedBox(height: 4.h),
                      _buildChip(
                        icon: Icons.access_time,
                        label:
                            _etaMinutes! < 1
                                ? '< 1 min'
                                : '~${_etaMinutes!.toInt()} min',
                        color: AppColorsDark.success,
                      ),
                    ],
                  ],
                ),
              ),

            // Legend
            Positioned(
              bottom: 12.h,
              left: 12.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(
                    color: AppColorsDark.success,
                    label: 'Pickup',
                  ),
                  SizedBox(height: 4.h),
                  _buildLegendItem(
                    color: AppColorsDark.error,
                    label: 'Delivery',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker({required IconData icon, required Color color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18.sp),
        ),
        Container(width: 2.w, height: 8.h, color: color),
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColorsDark.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.labelSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColorsDark.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.labelSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final order = widget.order;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: AppColorsDark.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store,
                  color: AppColorsDark.success,
                  size: 14.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: AppTextStyles.labelSmall().copyWith(
                        color: AppColorsDark.textSecondary,
                        fontSize: 10.sp,
                      ),
                    ),
                    Text(
                      order.storeName.isNotEmpty ? order.storeName : 'Store',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 13.w),
            child: Column(
              children: List.generate(
                3,
                (_) => Container(
                  width: 2.w,
                  height: 4.h,
                  margin: EdgeInsets.symmetric(vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColorsDark.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: AppColorsDark.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColorsDark.error,
                  size: 14.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery',
                      style: AppTextStyles.labelSmall().copyWith(
                        color: AppColorsDark.textSecondary,
                        fontSize: 10.sp,
                      ),
                    ),
                    Text(
                      order.userName,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${order.deliveryAddress.addressLine1}, '
                      '${order.deliveryAddress.area}, '
                      '${order.deliveryAddress.city}',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openDirections,
        icon: Icon(Icons.navigation, size: 20.sp),
        label: const Text('Get Directions'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Widget _buildNoLocationCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            size: 48.sp,
            color: AppColorsDark.textTertiary,
          ),
          SizedBox(height: 12.h),
          Text(
            'Location Not Available',
            style: AppTextStyles.titleSmall().copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'No coordinates found for this order.\nUse the address below to navigate.',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          _buildAddressCard(),
        ],
      ),
    );
  }
}
