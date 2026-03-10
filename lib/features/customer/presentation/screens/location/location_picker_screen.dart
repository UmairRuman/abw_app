import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../../addresses/data/models/address_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  /// true  → first-time setup, navigates to home after saving
  /// false → called from profile/checkout, pops after saving
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

  /// Pre-fill name & phone from logged-in user
  void _prefillFromAuth() {
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      _nameController.text = authState.user.name;
      _phoneController.text = authState.user.phone;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation!, 15.0);
        dev.log('✅ Location: ${position.latitude}, ${position.longitude}');
      } else {
        setState(() {
          _currentLocation = const LatLng(31.5204, 74.3587); // Lahore default
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
          // ── Map ────────────────────────────────────────────────────────
          if (_currentLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 15.0,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    setState(() => _currentLocation = position.center);
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

          // ── Fixed center pin ───────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 48.sp,
                  color: AppColorsDark.error,
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),

          // ── Loading overlay ────────────────────────────────────────────
          if (_isGettingLocation)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              ),
            ),

          // ── Top bar ────────────────────────────────────────────────────
          _buildTopBar(),

          // ── Bottom sheet ───────────────────────────────────────────────
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
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
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
              // Only show back button when NOT first-time setup
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
                      'Move map to adjust pin',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _getCurrentLocation,
                icon: const Icon(
                  Icons.my_location,
                  color: AppColorsDark.primary,
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
        child: SingleChildScrollView(
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
                    // First-time welcome message
                    if (widget.isFirstTime) ...[
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColorsDark.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColorsDark.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColorsDark.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'Set your location so we can show nearby stores and calculate delivery.',
                                style: AppTextStyles.bodySmall().copyWith(
                                  color: AppColorsDark.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // Pin location display
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
                                'Pin Location',
                                style: AppTextStyles.titleSmall().copyWith(
                                  color: AppColorsDark.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _currentLocation != null
                                    ? '${_currentLocation!.latitude.toStringAsFixed(5)}, ${_currentLocation!.longitude.toStringAsFixed(5)}'
                                    : 'Getting location...',
                                style: AppTextStyles.bodySmall().copyWith(
                                  color: AppColorsDark.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

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

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsDark.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
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

                    // Skip option for first-time (goes home without saving)
                    if (widget.isFirstTime) ...[
                      SizedBox(height: 10.h),
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

                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ],
          ),
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

      // 1. Save address to addresses collection
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

      // 2. ✅ Also update latitude/longitude on the customer document itself
      //    so splash screen can check it next time
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'latitude': _currentLocation!.latitude,
        'longitude': _currentLocation!.longitude,
        'address': _addressLine1Controller.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      dev.log(
        '✅ Location saved: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}',
      );

      if (mounted) {
        _showSnack('Location saved successfully!');

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          if (widget.isFirstTime) {
            // First time → go to home
            context.go('/customer/home');
          } else {
            // Normal usage → pop back
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      dev.log('❌ Save location error: $e');
      if (mounted) {
        _showSnack('Error: ${e.toString()}', isError: true);
      }
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
