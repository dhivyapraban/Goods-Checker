import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/driver_location_model.dart';
import 'api_service.dart';

/// Location service for GPS tracking
class LocationService {
  static LocationService? _instance;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;

  LocationService._();

  static LocationService get instance {
    _instance ??= LocationService._();
    return _instance!;
  }

  Position? get lastPosition => _lastPosition;

  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) print('📍 Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (kDebugMode) print('📍 Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode) print('📍 Location permission permanently denied');
      return false;
    }

    return true;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return null;

    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (kDebugMode) {
        print(
          '📍 Current location: ${_lastPosition!.latitude}, ${_lastPosition!.longitude}',
        );
      }
      return _lastPosition;
    } catch (e) {
      if (kDebugMode) print('📍 Error getting location: $e');
      return null;
    }
  }

  /// Start listening to location updates
  Stream<Position>? startLocationUpdates({
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).map((position) {
      _lastPosition = position;
      if (kDebugMode) {
        print(
          '📍 Location update: ${position.latitude}, ${position.longitude}',
        );
      }
      return position;
    });
  }

  /// Stop location updates
  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
        1000; // Convert meters to kilometers
  }

  /// Get bearing between two points
  double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  /// Check if location services are enabled
  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permissions)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Update driver location to backend
  Future<bool> updateDriverLocation({
    required String driverId,
    String? deliveryId,
    required Position position,
  }) async {
    try {
      final locationData = DriverLocationModel.fromPosition(
        driverId: driverId,
        deliveryId: deliveryId,
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
        speed: position.speed,
      );

      final response = await ApiService.instance.post(
        '/driver/location',
        data: locationData.toJson(),
      );

      if (response.isSuccess) {
        if (kDebugMode) print('📍 Location updated to backend');
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('📍 Error updating location: $e');
      return false;
    }
  }

  /// Fetch driver location for a shipment
  Future<DriverLocationModel?> getDriverLocationForShipment(
    String shipmentId,
  ) async {
    try {
      final response = await ApiService.instance.get<DriverLocationModel>(
        '/shipment/$shipmentId/driver-location',
        fromJson: (json) => DriverLocationModel.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        if (kDebugMode) {
          print(
            '📍 Driver location: ${response.data!.latitude}, ${response.data!.longitude}',
          );
        }
        return response.data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('📍 Error fetching driver location: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    stopLocationUpdates();
  }
}
