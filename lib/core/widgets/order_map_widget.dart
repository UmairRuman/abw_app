// lib/core/widgets/order_map_widget.dart
// Reusable map widget — drop into any screen with just an order object.
// Features:
//   ✅ Real road-following route via OSRM free API (no key needed)
//   ✅ Pickup + delivery markers with labels
//   ✅ Distance + ETA overlay chips
//   ✅ Address text card below map
//   ✅ Directions button → opens Google Maps / Apple Maps / OSM browser

import 'dart:convert';
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

  /// Height of the map tile only (address card + directions are below)
  final double mapHeight;

  const OrderMapWidget({super.key, required this.order, this.mapHeight = 260});

  @override
  State<OrderMapWidget> createState() => _OrderMapWidgetState();
}

class _OrderMapWidgetState extends State<OrderMapWidget> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  String? _routeError;
  double? _etaMinutes;
  double? _routeDistanceKm;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  // ── OSRM Free Routing API ─────────────────────────────────────────────────

  Future<void> _fetchRoute() async {
    final order = widget.order;

    if (order.pickupLatitude == null ||
        order.pickupLongitude == null ||
        order.deliveryLatitude == null ||
        order.deliveryLongitude == null) {
      setState(() {
        _isLoadingRoute = false;
        _routeError = 'no_coordinates';
      });
      return;
    }

    try {
      // OSRM public API — free, no key required
      final url =
          'http://router.project-osrm.org/route/v1/driving/'
          '${order.pickupLongitude},${order.pickupLatitude};'
          '${order.deliveryLongitude},${order.deliveryLatitude}'
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

          // OSRM returns [lng, lat] — we need LatLng(lat, lng)
          final points =
              coordinates
                  .map(
                    (c) => LatLng(
                      (c[1] as num).toDouble(),
                      (c[0] as num).toDouble(),
                    ),
                  )
                  .toList();

          // Extract ETA and distance from OSRM response
          final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;
          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;

          setState(() {
            _routePoints = points;
            _etaMinutes = durationSeconds / 60;
            _routeDistanceKm = distanceMeters / 1000;
            _isLoadingRoute = false;
          });

          // Fit map to show full route
          _fitMapToBounds();
        }
      } else {
        _fallbackToStraightLine();
      }
    } catch (e) {
      // Network error or timeout → fall back to straight line
      _fallbackToStraightLine();
    }
  }

  void _fallbackToStraightLine() {
    final order = widget.order;
    if (order.pickupLatitude == null) return;

    setState(() {
      _routePoints = [
        LatLng(order.pickupLatitude!, order.pickupLongitude!),
        LatLng(order.deliveryLatitude!, order.deliveryLongitude!),
      ];
      _routeDistanceKm = (order.distance ?? 0) / 1000;
      _isLoadingRoute = false;
    });
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
    final order = widget.order;
    if (order.deliveryLatitude == null) return;

    final lat = order.deliveryLatitude!;
    final lng = order.deliveryLongitude!;
    final pickLat = order.pickupLatitude!;
    final pickLng = order.pickupLongitude!;

    // Try Google Maps app first
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$pickLat,$pickLng'
      '&destination=$lat,$lng'
      '&travelmode=driving',
    );

    // Fallback: OpenStreetMap in browser
    final osmUrl = Uri.parse(
      'https://www.openstreetmap.org/directions'
      '?engine=fossgis_osrm_car'
      '&route=$pickLat,$pickLng;$lat,$lng',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(osmUrl)) {
      await launchUrl(osmUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps app'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final hasCoords =
        order.pickupLatitude != null && order.deliveryLatitude != null;

    if (!hasCoords) {
      return _buildNoLocationCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map tile
        _buildMapTile(order),
        SizedBox(height: 12.h),
        // Address card
        _buildAddressCard(order),
        SizedBox(height: 12.h),
        // Directions button
        _buildDirectionsButton(),
      ],
    );
  }

  Widget _buildMapTile(OrderModel order) {
    final pickupPoint = LatLng(order.pickupLatitude!, order.pickupLongitude!);
    final deliveryPoint = LatLng(
      order.deliveryLatitude!,
      order.deliveryLongitude!,
    );

    final centerLat = (order.pickupLatitude! + order.deliveryLatitude!) / 2;
    final centerLng = (order.pickupLongitude! + order.deliveryLongitude!) / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: widget.mapHeight.h,
        child: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(centerLat, centerLng),
                initialZoom: 13.0,
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.abw.app',
                  maxZoom: 19,
                ),

                // Route polyline
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

                // Markers
                MarkerLayer(
                  markers: [
                    // 🟢 Pickup marker
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

                    // 🔴 Delivery marker
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

            // Loading overlay
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

            // ETA + Distance chips (top-right overlay)
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

            // Legend (bottom-left)
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
        // Pin tip
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

  Widget _buildAddressCard(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Column(
        children: [
          // Pickup address row
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
                      order.storeName,
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

          // Dotted divider
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

          // Delivery address row
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
          // Still show address even without coords
          _buildAddressCard(widget.order),
        ],
      ),
    );
  }
}
