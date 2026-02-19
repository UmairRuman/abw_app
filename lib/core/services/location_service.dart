// lib/core/services/location_service.dart
// MILESTONE 3 - Location service for GPS coordinates

import 'package:geolocator/geolocator.dart';
import 'dart:developer' as dev;

class LocationService {
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location with permission handling
  /// Returns null if permission denied or service disabled
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        dev.log('❌ Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          dev.log('❌ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        dev.log('❌ Location permission denied forever');
        return null;
      }

      // Get current position
      dev.log('📍 Getting current location...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      dev.log('✅ Location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      dev.log('❌ Error getting location: $e');
      return null;
    }
  }

  /// Get last known location (faster, but might be stale)
  static Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      dev.log('❌ Error getting last known location: $e');
      return null;
    }
  }

  /// Calculate straight-line distance between two coordinates (in kilometers)
  /// Uses Haversine formula
  static double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );

    // Convert meters to kilometers
    return distanceInMeters / 1000;
  }

  /// Format distance for display
  /// e.g., "2.5 km" or "850 m"
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      final meters = (distanceInKm * 1000).round();
      return '$meters m';
    }
    return '${distanceInKm.toStringAsFixed(1)} km';
  }

  /// Open device location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
