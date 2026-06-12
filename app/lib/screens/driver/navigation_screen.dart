import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/delivery_model.dart';
import '../../services/location_service.dart';

/// Navigation screen with Google Maps
class NavigationScreen extends StatefulWidget {
  final DeliveryModel delivery;

  const NavigationScreen({super.key, required this.delivery});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService.instance;

  LatLng? _currentLocation;
  StreamSubscription? _locationSubscription;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isNavigatingToPickup = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _setupMarkers();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required for navigation'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _updateMarkers();
    }

    // Start listening to location updates
    _locationSubscription = _locationService.startLocationUpdates()?.listen((
      position,
    ) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _updateMarkers();

        // Send location update to backend
        _locationService.updateDriverLocation(
          driverId: widget.delivery.driverId,
          deliveryId: widget.delivery.id,
          position: position,
        );
      }
    });
  }

  void _setupMarkers() {
    _isNavigatingToPickup = widget.delivery.status == 'EN_ROUTE_TO_PICKUP';
    _updateMarkers();
    _updatePolyline();
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Pickup marker
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.delivery.pickupLat, widget.delivery.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup',
          snippet: widget.delivery.pickupLocation,
        ),
      ),
    );

    // Drop marker
    markers.add(
      Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(widget.delivery.dropLat, widget.delivery.dropLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Drop',
          snippet: widget.delivery.dropLocation,
        ),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  void _updatePolyline() {
    final destination = _isNavigatingToPickup
        ? LatLng(widget.delivery.pickupLat, widget.delivery.pickupLng)
        : LatLng(widget.delivery.dropLat, widget.delivery.dropLng);

    // Simple straight line polyline (in production, use Directions API)
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: _currentLocation != null
          ? [_currentLocation!, destination]
          : [
              LatLng(widget.delivery.pickupLat, widget.delivery.pickupLng),
              LatLng(widget.delivery.dropLat, widget.delivery.dropLng),
            ],
      color: AppTheme.primary,
      width: 4,
    );

    setState(() {
      _polylines = {polyline};
    });
  }

  void _recenterMap() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
  }

  LatLng get _destination => _isNavigatingToPickup
      ? LatLng(widget.delivery.pickupLat, widget.delivery.pickupLng)
      : LatLng(widget.delivery.dropLat, widget.delivery.dropLng);

  double get _distanceToDestination {
    if (_currentLocation == null) return widget.delivery.distanceKm;
    return _locationService.calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _destination.latitude,
      _destination.longitude,
    );
  }

  int get _etaMinutes {
    // Assume 40 km/h average speed
    return (_distanceToDestination / 40 * 60).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.delivery.pickupLat,
                widget.delivery.pickupLng,
              ),
              zoom: 13,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // Set dark map style
              _mapController!.setMapStyle(_darkMapStyle);
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.surface,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isNavigatingToPickup
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: _isNavigatingToPickup
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isNavigatingToPickup ? 'To Pickup' : 'To Drop',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ETA and Distance
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.access_time,
                          '$_etaMinutes min',
                          'ETA',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.straighten,
                          '${_distanceToDestination.toStringAsFixed(1)} km',
                          'Distance',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Destination
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _isNavigatingToPickup
                                ? AppTheme.success
                                : AppTheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isNavigatingToPickup
                                    ? 'PICKUP LOCATION'
                                    : 'DROP LOCATION',
                                style: AppTheme.caption,
                              ),
                              Text(
                                _isNavigatingToPickup
                                    ? widget.delivery.pickupLocation
                                    : widget.delivery.dropLocation,
                                style: AppTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Report issue
                          },
                          icon: const Icon(Icons.warning_outlined),
                          label: const Text('Report Issue'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(
                            Icons.my_location,
                            color: Colors.black,
                          ),
                          onPressed: _recenterMap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTheme.labelLarge),
              Text(label, style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  // Dark map style
  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#181818"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#373737"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3c3c3c"}]},
  {"featureType": "road.highway.controlled_access", "elementType": "geometry", "stylers": [{"color": "#4e4e4e"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3d3d3d"}]}
]
''';
}
