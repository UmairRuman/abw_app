// lib/features/customer/presentation/screens/location/location_picker_screen.dart
// COMPLETE REPLACEMENT
//
// ROOT CAUSE FIX: Old layout used Stack where bottom sheet OVERLAID the map,
// so the pin centered on full screen was half-hidden behind the bottom sheet.
//
// NEW LAYOUT: Column → [TopBar | Map(Expanded) | BottomSheet(fixed)]
// Pin is centered inside the Map widget only → always fully visible.
// FractionalTranslation(-0.5 y) moves it up so the TIP of the pin
// is exactly at the map center (the point Firestore records).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../../addresses/data/models/address_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  final bool isFirstTime;
  const LocationPickerScreen({super.key, this.isFirstTime = false});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  bool _isGettingLocation = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _landmarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillFromAuth();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _prefillFromAuth() {
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      _nameController.text = authState.user.name;
      _phoneController.text = authState.user.phone ?? '';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _currentLocation = null;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack(
          'Location permission denied. Enable it in Settings.',
          isError: true,
        );
        if (mounted)
          setState(() => _currentLocation = const LatLng(30.3753, 69.3451));
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (mounted) {
        setState(
          () =>
              _currentLocation = LatLng(position.latitude, position.longitude),
        );
        try {
          _mapController.move(_currentLocation!, 15.5);
        } catch (_) {}
      }
    } catch (e) {
      dev.log('GPS error: $e');
      if (mounted) {
        _showSnack(
          'Could not get location. Move the pin manually.',
          isError: true,
        );
        setState(() => _currentLocation = const LatLng(30.3753, 69.3451));
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: SafeArea(
        // ✅ Column — top bar | map (fills space) | bottom sheet
        child: Column(
          children: [
            _buildTopBar(),

            // ── Map area ─────────────────────────────────────────────────
            Expanded(
              child:
                  _isGettingLocation || _currentLocation == null
                      ? _buildLoadingState()
                      : Stack(
                        children: [
                          // Map
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentLocation!,
                              initialZoom: 15.5,
                              onPositionChanged: (pos, hasGesture) {
                                if (hasGesture && mounted) {
                                  setState(() => _currentLocation = pos.center);
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.abw.app',
                              ),
                            ],
                          ),

                          // ✅ Pin — centered in MAP widget, tip at exact center
                          // FractionalTranslation(-0.5 y) shifts icon up by half
                          // its own height → bottom tip lands at center point
                          Center(
                            child: FractionalTranslation(
                              translation: const Offset(0, -0.5),
                              child: Icon(
                                Icons.location_on,
                                size: 52.sp,
                                color: AppColorsDark.error,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Coordinates chip (top-left)
                          Positioned(
                            top: 10.h,
                            left: 10.w,
                            right: 10.w,
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorsDark.surface.withOpacity(
                                    0.92,
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14.sp,
                                      color: AppColorsDark.primary,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '${_currentLocation!.latitude.toStringAsFixed(5)},  '
                                      '${_currentLocation!.longitude.toStringAsFixed(5)}',
                                      style: AppTextStyles.bodySmall().copyWith(
                                        color: AppColorsDark.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
            ),

            // ── Bottom sheet — sits below map, never overlaps ──────────
            _buildBottomSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppColorsDark.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColorsDark.primary),
            SizedBox(height: 16.h),
            Text(
              'Getting your location...',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please allow location access if prompted',
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: const BoxDecoration(
        color: AppColorsDark.surface,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          if (!widget.isFirstTime)
            IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColorsDark.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          SizedBox(width: widget.isFirstTime ? 16.w : 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isFirstTime
                      ? 'Set Your Delivery Location'
                      : 'Select Delivery Location',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Move map to place pin · tip = exact location',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location, color: AppColorsDark.primary),
            tooltip: 'Use GPS',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColorsDark.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      // ✅ Constrain max height so map always has space
      constraints: BoxConstraints(maxHeight: 420.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColorsDark.textTertiary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isFirstTime) ...[
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColorsDark.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColorsDark.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColorsDark.primary,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Move the map so the pin tip is on your location, then fill details.',
                              style: AppTextStyles.bodySmall().copyWith(
                                color: AppColorsDark.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                  ],
                  _buildTextField(
                    controller: _nameController,
                    label: 'Your Name',
                    icon: Icons.person,
                    hint: 'Full name',
                  ),
                  SizedBox(height: 10.h),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    hint: '03001234567',
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 10.h),
                  _buildTextField(
                    controller: _addressLine1Controller,
                    label: 'House/Flat No, Building',
                    icon: Icons.home,
                    hint: 'e.g., Flat 2A, Blue Tower',
                  ),
                  SizedBox(height: 10.h),
                  _buildTextField(
                    controller: _landmarkController,
                    label: 'Nearby Landmark (Optional)',
                    icon: Icons.location_searching,
                    hint: 'e.g., Near Subway',
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsDark.primary,
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child:
                          _isSaving
                              ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColorsDark.white,
                                ),
                              )
                              : Text(
                                widget.isFirstTime
                                    ? 'Confirm & Continue'
                                    : 'Confirm Location',
                                style: AppTextStyles.button(),
                              ),
                    ),
                  ),
                  if (widget.isFirstTime) ...[
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.go('/customer/home'),
                        child: Text(
                          'Skip for now',
                          style: AppTextStyles.labelMedium().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium().copyWith(
        color: AppColorsDark.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20.sp, color: AppColorsDark.primary),
        filled: true,
        fillColor: AppColorsDark.surfaceVariant,
        labelStyle: AppTextStyles.bodySmall().copyWith(
          color: AppColorsDark.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
        ),
      ),
    );
  }

  Future<void> _saveLocation() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter your name', isError: true);
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showSnack('Please enter your phone number', isError: true);
      return;
    }
    if (_addressLine1Controller.text.trim().isEmpty) {
      _showSnack('Please enter your address', isError: true);
      return;
    }
    if (_currentLocation == null) {
      _showSnack('Please select a location on the map', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authState = ref.read(authProvider);
      if (authState is! Authenticated) throw Exception('Not authenticated');
      final userId = authState.user.id;

      final address = AddressModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        label: 'Home',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: null,
        area: 'Area',
        city: 'City',
        state: 'Punjab',
        postalCode: '',
        country: 'Pakistan',
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        isDefault: true,
        addressType: 'home',
        landmark:
            _landmarkController.text.trim().isEmpty
                ? null
                : _landmarkController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(addressesProvider.notifier).addAddress(address);

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'latitude': _currentLocation!.latitude,
        'longitude': _currentLocation!.longitude,
        'address': _addressLine1Controller.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnack('Location saved!');
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          if (widget.isFirstTime) {
            context.go('/customer/home');
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      dev.log('Save location error: $e');
      if (mounted) _showSnack('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColorsDark.error : AppColorsDark.success,
      ),
    );
  }
}
