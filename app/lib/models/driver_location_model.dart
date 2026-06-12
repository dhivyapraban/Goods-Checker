/// Driver location model for real-time tracking
class DriverLocationModel {
  final String driverId;
  final String? deliveryId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  DriverLocationModel({
    required this.driverId,
    this.deliveryId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    return DriverLocationModel(
      driverId: json['driverId'] ?? '',
      deliveryId: json['deliveryId'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'deliveryId': deliveryId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from Geolocator Position
  factory DriverLocationModel.fromPosition({
    required String driverId,
    String? deliveryId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) {
    return DriverLocationModel(
      driverId: driverId,
      deliveryId: deliveryId,
      latitude: latitude,
      longitude: longitude,
      heading: heading,
      speed: speed,
      timestamp: DateTime.now(),
    );
  }
}
