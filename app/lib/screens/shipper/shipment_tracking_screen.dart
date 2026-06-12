import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/shipment_model.dart';
import '../../models/driver_location_model.dart';
import '../../services/location_service.dart';

/// Shipment tracking screen with real-time driver location
class ShipmentTrackingScreen extends StatefulWidget {
  final ShipmentModel shipment;

  const ShipmentTrackingScreen({super.key, required this.shipment});

  @override
  State<ShipmentTrackingScreen> createState() => _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState extends State<ShipmentTrackingScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService.instance;

  DriverLocationModel? _driverLocation;
  Timer? _locationUpdateTimer;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initTracking() async {
    await _fetchDriverLocation();
    _setupMarkers();
    _updatePolyline();

    // Auto-refresh driver location every 10 seconds
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchDriverLocation(),
    );
  }

  Future<void> _fetchDriverLocation() async {
    final location = await _locationService.getDriverLocationForShipment(
      widget.shipment.id,
    );

    if (location != null && mounted) {
      setState(() {
        _driverLocation = location;
        _isLoading = false;
      });
      _updateMarkers();
      _updatePolyline();
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupMarkers() {
    _updateMarkers();
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Pickup marker
    if (widget.shipment.pickupLat != null &&
        widget.shipment.pickupLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            widget.shipment.pickupLat!,
            widget.shipment.pickupLng!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: widget.shipment.pickupLocation ?? 'Pickup location',
          ),
        ),
      );
    }

    // Drop marker
    if (widget.shipment.dropLat != null && widget.shipment.dropLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(widget.shipment.dropLat!, widget.shipment.dropLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Drop',
            snippet: widget.shipment.dropLocation ?? 'Drop location',
          ),
        ),
      );
    }

    // Driver marker (if available)
    if (_driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            _driverLocation!.latitude,
            _driverLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Driver',
            snippet: widget.shipment.delivery?.driver?.name ?? 'Driver',
          ),
          rotation: _driverLocation!.heading ?? 0,
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _updatePolyline() {
    if (_driverLocation == null ||
        widget.shipment.pickupLat == null ||
        widget.shipment.dropLat == null) {
      return;
    }

    // Create polyline from driver to pickup/drop
    final driverPos = LatLng(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
    );

    final pickupPos = LatLng(
      widget.shipment.pickupLat!,
      widget.shipment.pickupLng!,
    );

    final dropPos = LatLng(widget.shipment.dropLat!, widget.shipment.dropLng!);

    // Determine if driver is heading to pickup or drop
    final isHeadingToPickup =
        widget.shipment.status == 'DRIVER_ACCEPTED' ||
        widget.shipment.status == 'DRIVER_NOTIFIED';

    final destination = isHeadingToPickup ? pickupPos : dropPos;

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [driverPos, destination],
      color: AppTheme.primary,
      width: 4,
    );

    // Route polyline (pickup to drop)
    final routePolyline = Polyline(
      polylineId: const PolylineId('full_route'),
      points: [pickupPos, dropPos],
      color: AppTheme.textMuted,
      width: 3,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    );

    setState(() {
      _polylines = {polyline, routePolyline};
    });
  }

  void _recenterMap() {
    if (_driverLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
        ),
      );
    }
  }

  double get _distanceToDestination {
    if (_driverLocation == null ||
        widget.shipment.pickupLat == null ||
        widget.shipment.dropLat == null) {
      return 0;
    }

    final isHeadingToPickup =
        widget.shipment.status == 'DRIVER_ACCEPTED' ||
        widget.shipment.status == 'DRIVER_NOTIFIED';

    final destLat = isHeadingToPickup
        ? widget.shipment.pickupLat!
        : widget.shipment.dropLat!;
    final destLng = isHeadingToPickup
        ? widget.shipment.pickupLng!
        : widget.shipment.dropLng!;

    return _locationService.calculateDistance(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
      destLat,
      destLng,
    );
  }

  int get _etaMinutes {
    // Assume 40 km/h average speed
    return (_distanceToDestination / 40 * 60).round();
  }

  Future<void> _callDriver() async {
    final phone = widget.shipment.delivery?.driver?.phone;
    if (phone == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver phone number not available'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot make phone call'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          if (!_isLoading)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _driverLocation != null
                    ? LatLng(
                        _driverLocation!.latitude,
                        _driverLocation!.longitude,
                      )
                    : LatLng(
                        widget.shipment.pickupLat ?? 0,
                        widget.shipment.pickupLng ?? 0,
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
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
            ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: AppTheme.background,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
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
                        const Icon(
                          Icons.local_shipping,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.shipment.statusLabel,
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

                  // Driver info (if available)
                  if (widget.shipment.delivery?.driver != null)
                    _buildDriverInfo(),

                  const SizedBox(height: 16),

                  // ETA and Distance
                  if (_driverLocation != null)
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

                  if (_driverLocation == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.warning),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Driver location not available yet',
                              style: TextStyle(color: AppTheme.warning),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Route info
                  _buildRouteInfo(),

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      if (widget.shipment.delivery?.driver?.phone != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _callDriver,
                            icon: const Icon(Icons.phone),
                            label: const Text('Call Driver'),
                          ),
                        ),
                      if (widget.shipment.delivery?.driver?.phone != null)
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

  Widget _buildDriverInfo() {
    final driver = widget.shipment.delivery!.driver!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary,
            child: Text(
              driver.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name, style: AppTheme.bodyLarge),
                if (driver.phone != null)
                  Text(driver.phone!, style: AppTheme.caption),
              ],
            ),
          ),
          if (driver.rating != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 14, color: AppTheme.warning),
                  const SizedBox(width: 4),
                  Text(
                    driver.rating!.toStringAsFixed(1),
                    style: AppTheme.caption.copyWith(color: AppTheme.warning),
                  ),
                ],
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

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Pickup
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PICKUP', style: AppTheme.caption),
                    Text(
                      widget.shipment.pickupLocation ?? 'Pickup location',
                      style: AppTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Drop
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DROP', style: AppTheme.caption),
                    Text(
                      widget.shipment.dropLocation ?? 'Drop location',
                      style: AppTheme.bodySmall,
                      maxLines: 1,
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
