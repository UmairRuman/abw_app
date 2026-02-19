// lib/features/auth/presentation/screens/location/location_capture_screen.dart
// MILESTONE 3 - Capture user location on first signup

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../core/services/location_service.dart';

class LocationCaptureScreen extends ConsumerStatefulWidget {
  final String userId;
  final String role; // 'customer', 'rider', etc.

  const LocationCaptureScreen({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  ConsumerState<LocationCaptureScreen> createState() =>
      _LocationCaptureScreenState();
}

class _LocationCaptureScreenState extends ConsumerState<LocationCaptureScreen> {
  bool _isLoading = false;
  Position? _currentPosition;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = 'Location services are disabled. Please enable them.';
      });
      return;
    }

    final permission = await LocationService.checkPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        _statusMessage = 'Location permission required for delivery.';
      });
    }
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Getting your location...';
    });

    try {
      final position = await LocationService.getCurrentLocation();

      if (position == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage =
                'Unable to get location. Please check permissions.';
          });
        }
        return;
      }

      setState(() {
        _currentPosition = position;
        _statusMessage =
            'Location captured: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });

      // Save to Firestore
      await _saveLocationToFirestore(position);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location saved successfully! ✅'),
            backgroundColor: AppColorsDark.success,
          ),
        );

        // Navigate to home
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          if (widget.role == 'customer') {
            context.go('/customer/home');
          } else if (widget.role == 'rider') {
            context.go('/rider/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _saveLocationToFirestore(Position position) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
          'defaultLatitude': position.latitude,
          'defaultLongitude': position.longitude,
          'locationCaptured': true,
          'locationCapturedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _skipForNow() async {
    if (mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: AppColorsDark.surface,
              title: Text(
                'Skip Location?',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                ),
              ),
              content: Text(
                'You can add your location later from settings. However, delivery distance calculations will be less accurate.',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Skip'),
                ),
              ],
            ),
      );

      if (confirm == true && mounted) {
        if (widget.role == 'customer') {
          context.go('/customer/home');
        } else if (widget.role == 'rider') {
          context.go('/rider/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Enable Location',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),

              // Location Icon
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  gradient: AppColorsDark.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColorsDark.white,
                  size: 60.sp,
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                'Enable Your Location',
                style: AppTextStyles.headlineMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12.h),

              // Description
              Text(
                'We need your location to calculate accurate delivery distances and provide better service.',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32.h),

              // Benefits
              _buildBenefit(
                Icons.delivery_dining,
                'Accurate Delivery',
                'Calculate exact delivery distance',
              ),
              SizedBox(height: 16.h),
              _buildBenefit(
                Icons.schedule,
                'Better Timing',
                'Get accurate delivery time estimates',
              ),
              SizedBox(height: 16.h),
              _buildBenefit(
                Icons.discount,
                'Fair Pricing',
                'Delivery fees based on actual distance',
              ),

              SizedBox(height: 32.h),

              // Status Message
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColorsDark.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColorsDark.info.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _currentPosition != null
                            ? Icons.check_circle
                            : Icons.info_outline,
                        size: 18.sp,
                        color: AppColorsDark.info,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Enable Location Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _captureLocation,
                  icon:
                      _isLoading
                          ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColorsDark.white,
                            ),
                          )
                          : Icon(Icons.my_location, size: 20.sp),
                  label: Text(
                    _isLoading ? 'Getting Location...' : 'Enable Location',
                    style: AppTextStyles.button(),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // Skip Button
              TextButton(
                onPressed: _isLoading ? null : _skipForNow,
                child: Text(
                  'Skip for now',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColorsDark.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppColorsDark.primary, size: 24.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
