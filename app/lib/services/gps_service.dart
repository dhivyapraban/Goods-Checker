import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// GPS Service for background location tracking
class GPSService {
  static GPSService? _instance;
  final ApiService _apiService = ApiService.instance;

  StreamSubscription<Position>? _positionStream;
  Timer? _locationUpdateTimer;
  String? _currentTruckId;

  static const Duration _updateInterval = Duration(seconds: 30);
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters
  );

  GPSService._();

  static GPSService get instance {
    _instance ??= GPSService._();
    return _instance!;
  }

  /// Check if location permission is granted
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (kDebugMode) print('Error getting position: $e');
      return null;
    }
  }

  /// Start tracking location and sending to backend
  Future<void> startTracking(String truckId) async {
    if (_positionStream != null) {
      await stopTracking();
    }

    _currentTruckId = truckId;

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      if (kDebugMode) print('Location permission not granted');
      return;
    }

    // Start listening to position stream
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: _locationSettings,
        ).listen(
          (Position position) {
            _onPositionUpdate(position);
          },
          onError: (error) {
            if (kDebugMode) print('Position stream error: $error');
          },
        );

    // Also set up periodic updates as backup
    _locationUpdateTimer = Timer.periodic(_updateInterval, (_) async {
      final position = await getCurrentPosition();
      if (position != null) {
        _onPositionUpdate(position);
      }
    });

    if (kDebugMode) print('📍 GPS tracking started for truck: $truckId');
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    _currentTruckId = null;

    if (kDebugMode) print('📍 GPS tracking stopped');
  }

  /// Handle position update
  void _onPositionUpdate(Position position) async {
    if (_currentTruckId == null) return;

    try {
      await _apiService.updateTruckLocation(
        truckId: _currentTruckId!,
        lat: position.latitude,
        lng: position.longitude,
        speed: position.speed,
        heading: position.heading,
      );

      if (kDebugMode) {
        print(
          '📍 Location updated: ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error updating location: $e');
    }
  }

  /// Calculate distance between two points (in meters)
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Check if currently tracking
  bool get isTracking => _positionStream != null;
}
