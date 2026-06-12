import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_theme.dart';
import '../services/location_service.dart';

/// Interactive map widget for picking pickup and drop locations
class LocationPickerMap extends StatefulWidget {
  final double initialPickupLat;
  final double initialPickupLng;
  final double initialDropLat;
  final double initialDropLng;
  final Function(double lat, double lng) onPickupSelected;
  final Function(double lat, double lng) onDropSelected;

  const LocationPickerMap({
    super.key,
    required this.initialPickupLat,
    required this.initialPickupLng,
    required this.initialDropLat,
    required this.initialDropLng,
    required this.onPickupSelected,
    required this.onDropSelected,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService.instance;

  late LatLng _pickupLocation;
  late LatLng _dropLocation;
  Set<Marker> _markers = {};

  bool _isSettingPickup = true; // true = setting pickup, false = setting drop

  @override
  void initState() {
    super.initState();
    _pickupLocation = LatLng(widget.initialPickupLat, widget.initialPickupLng);
    _dropLocation = LatLng(widget.initialDropLat, widget.initialDropLng);
    _updateMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Pickup marker
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
    );

    // Drop marker
    markers.add(
      Marker(
        markerId: const MarkerId('drop'),
        position: _dropLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop Location'),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  void _onMapTap(LatLng position) {
    setState(() {
      if (_isSettingPickup) {
        _pickupLocation = position;
        widget.onPickupSelected(position.latitude, position.longitude);
      } else {
        _dropLocation = position;
        widget.onDropSelected(position.latitude, position.longitude);
      }
    });
    _updateMarkers();

    // Animate camera to the new position
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  Future<void> _useCurrentLocation() async {
    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      final currentLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _pickupLocation = currentLocation;
        _isSettingPickup = true;
      });
      widget.onPickupSelected(position.latitude, position.longitude);
      _updateMarkers();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 14),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup set to current location'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openFullScreenMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenMapView(
          pickupLocation: _pickupLocation,
          dropLocation: _dropLocation,
          isSettingPickup: _isSettingPickup,
          onLocationSelected: (LatLng position, bool isPickup) {
            setState(() {
              if (isPickup) {
                _pickupLocation = position;
                widget.onPickupSelected(position.latitude, position.longitude);
              } else {
                _dropLocation = position;
                widget.onDropSelected(position.latitude, position.longitude);
              }
            });
            _updateMarkers();
          },
          onModeChanged: (bool isPickup) {
            setState(() {
              _isSettingPickup = isPickup;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickupLocation,
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController!.setMapStyle(_darkMapStyle);
            },
            onTap: _onMapTap,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Mode selector (top)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Expanded(
                  child: _buildModeButton(
                    'Set Pickup',
                    Icons.arrow_upward,
                    AppTheme.success,
                    _isSettingPickup,
                    () => setState(() => _isSettingPickup = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeButton(
                    'Set Drop',
                    Icons.arrow_downward,
                    AppTheme.error,
                    !_isSettingPickup,
                    () => setState(() => _isSettingPickup = false),
                  ),
                ),
              ],
            ),
          ),

          // Use current location button (bottom right)
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Expand to full screen button
                FloatingActionButton.small(
                  heroTag: 'expand',
                  onPressed: () => _openFullScreenMap(context),
                  backgroundColor: AppTheme.surface.withOpacity(0.9),
                  child: const Icon(Icons.fullscreen, color: AppTheme.primary),
                ),
                const SizedBox(height: 8),
                // Use current location button
                FloatingActionButton.small(
                  heroTag: 'location',
                  onPressed: _useCurrentLocation,
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ],
            ),
          ),

          // Info text (bottom left)
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: _isSettingPickup ? AppTheme.success : AppTheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to set ${_isSettingPickup ? 'pickup' : 'drop'}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.9)
              : AppTheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppTheme.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
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

/// Full-screen map view for better location selection
class _FullScreenMapView extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng dropLocation;
  final bool isSettingPickup;
  final Function(LatLng position, bool isPickup) onLocationSelected;
  final Function(bool isPickup) onModeChanged;

  const _FullScreenMapView({
    required this.pickupLocation,
    required this.dropLocation,
    required this.isSettingPickup,
    required this.onLocationSelected,
    required this.onModeChanged,
  });

  @override
  State<_FullScreenMapView> createState() => _FullScreenMapViewState();
}

class _FullScreenMapViewState extends State<_FullScreenMapView> {
  GoogleMapController? _mapController;
  late LatLng _pickupLocation;
  late LatLng _dropLocation;
  late bool _isSettingPickup;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _pickupLocation = widget.pickupLocation;
    _dropLocation = widget.dropLocation;
    _isSettingPickup = widget.isSettingPickup;
    _updateMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
    );

    markers.add(
      Marker(
        markerId: const MarkerId('drop'),
        position: _dropLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop Location'),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  void _onMapTap(LatLng position) {
    setState(() {
      if (_isSettingPickup) {
        _pickupLocation = position;
      } else {
        _dropLocation = position;
      }
    });
    _updateMarkers();
    widget.onLocationSelected(position, _isSettingPickup);

    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _isSettingPickup ? _pickupLocation : _dropLocation,
              zoom: 13,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController!.setMapStyle(_darkMapStyle);
            },
            onTap: _onMapTap,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),

          // Top bar with close button and mode selector
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Close button
                      CircleAvatar(
                        backgroundColor: AppTheme.surface.withOpacity(0.9),
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mode selector
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildModeButton(
                                'Set Pickup',
                                Icons.arrow_upward,
                                AppTheme.success,
                                _isSettingPickup,
                                () {
                                  setState(() => _isSettingPickup = true);
                                  widget.onModeChanged(true);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildModeButton(
                                'Set Drop',
                                Icons.arrow_downward,
                                AppTheme.error,
                                !_isSettingPickup,
                                () {
                                  setState(() => _isSettingPickup = false);
                                  widget.onModeChanged(false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Info text at bottom
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: _isSettingPickup ? AppTheme.success : AppTheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap anywhere on the map to set ${_isSettingPickup ? 'pickup' : 'drop'} location',
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.9)
              : AppTheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppTheme.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.black : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
