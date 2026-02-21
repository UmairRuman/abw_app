// lib/features/customer/presentation/screens/location/location_picker_screen.dart
// FOODPANDA-STYLE LOCATION PICKER

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as dev;

import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../../addresses/data/models/address_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  bool _isGettingLocation = false;
  bool _isSaving = false;

  // Address details
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _landmarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final position = await LocationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });

        // Move map to current location
        _mapController.move(_currentLocation!, 15.0);

        dev.log('✅ Location: ${position.latitude}, ${position.longitude}');
      } else {
        // Default to a city center if GPS fails
        setState(() {
          _currentLocation = const LatLng(31.5204, 74.3587); // Lahore, Pakistan
        });
      }
    } catch (e) {
      dev.log('❌ Error getting location: $e');
      setState(() {
        _currentLocation = const LatLng(31.5204, 74.3587);
      });
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: Stack(
        children: [
          // Map
          if (_currentLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 15.0,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    setState(() {
                      _currentLocation = position.center;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.abw.app',
                ),
              ],
            ),

          // Center pin (fixed in center)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 48.sp,
                  color: AppColorsDark.error,
                ),
                SizedBox(height: 40.h), // Offset to center the bottom of pin
              ],
            ),
          ),

          // Loading overlay
          if (_isGettingLocation)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              ),
            ),

          // Top bar
          _buildTopBar(),

          // Bottom sheet
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: const BoxDecoration(
            color: AppColorsDark.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColorsDark.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Delivery Location',
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Move map to adjust pin',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Current location button
              IconButton(
                onPressed: _getCurrentLocation,
                icon: const Icon(
                  Icons.my_location,
                  color: AppColorsDark.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColorsDark.surface,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
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
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location info
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColorsDark.primary,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Location',
                              style: AppTextStyles.titleSmall().copyWith(
                                color: AppColorsDark.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _currentLocation != null
                                  ? '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}'
                                  : 'Loading...',
                              style: AppTextStyles.bodySmall().copyWith(
                                color: AppColorsDark.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Quick details form
                  _buildTextField(
                    controller: _nameController,
                    label: 'Your Name',
                    icon: Icons.person,
                    hint: 'Full name',
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    hint: '03001234567',
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    controller: _addressLine1Controller,
                    label: 'House/Flat No, Building',
                    icon: Icons.home,
                    hint: 'e.g., Flat 2A, Blue Tower',
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    controller: _landmarkController,
                    label: 'Nearby Landmark (Optional)',
                    icon: Icons.location_searching,
                    hint: 'e.g., Near Subway',
                  ),

                  SizedBox(height: 20.h),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveLocation,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
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
                                'Confirm Location',
                                style: AppTextStyles.button(),
                              ),
                    ),
                  ),
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
        prefixIcon: Icon(icon, size: 20.sp),
        filled: true,
        fillColor: AppColorsDark.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _saveLocation() async {
    // Validate
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: AppColorsDark.error,
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: AppColorsDark.error,
        ),
      );
      return;
    }

    if (_addressLine1Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your address'),
          backgroundColor: AppColorsDark.error,
        ),
      );
      return;
    }

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: AppColorsDark.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authState = ref.read(authProvider);
      if (authState is! Authenticated) {
        throw Exception('Not authenticated');
      }

      // Create address
      final address = AddressModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: authState.user.id,
        label: 'Home', // Default label
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: null,
        area: 'Area', // TODO: Get from reverse geocoding
        city: 'City', // TODO: Get from reverse geocoding
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

      // Save address
      final success = await ref
          .read(addressesProvider.notifier)
          .addAddress(address);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Location saved successfully!'),
            backgroundColor: AppColorsDark.success,
          ),
        );

        // Navigate back to checkout
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
