/// Optimized Route model for driver's assigned routes
class RouteModel {
  final String id;
  final String courierCompanyId;
  final String truckId;
  final String driverId;

  // Route details
  final String? routePolyline;
  final List<Waypoint>? waypoints;
  final double totalDistance;
  final double totalDuration;

  // Schedule
  final DateTime estimatedStartTime;
  final DateTime estimatedEndTime;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Cargo summary
  final int totalPackages;
  final double totalWeight;
  final double totalVolume;
  final double utilizationPercent;

  // Optimization metrics
  final double baselineDistance;
  final double carbonSaved;
  final double emptyMilesSaved;
  final bool isTSPOptimized;

  // Status
  final String status; // PENDING, ALLOCATED, ACTIVE, COMPLETED, CANCELLED

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final List<DeliveryInfo>? deliveries;

  RouteModel({
    required this.id,
    required this.courierCompanyId,
    required this.truckId,
    required this.driverId,
    this.routePolyline,
    this.waypoints,
    this.totalDistance = 0.0,
    this.totalDuration = 0.0,
    required this.estimatedStartTime,
    required this.estimatedEndTime,
    this.startedAt,
    this.completedAt,
    required this.totalPackages,
    required this.totalWeight,
    required this.totalVolume,
    required this.utilizationPercent,
    required this.baselineDistance,
    required this.carbonSaved,
    required this.emptyMilesSaved,
    this.isTSPOptimized = true,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deliveries,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] ?? '',
      courierCompanyId: json['courierCompanyId'] ?? '',
      truckId: json['truckId'] ?? '',
      driverId: json['driverId'] ?? '',
      routePolyline: json['routePolyline'],
      waypoints: (json['waypoints'] as List<dynamic>?)
          ?.map((w) => Waypoint.fromJson(w))
          .toList(),
      totalDistance: (json['totalDistance'] ?? 0).toDouble(),
      totalDuration: (json['totalDuration'] ?? 0).toDouble(),
      estimatedStartTime: json['estimatedStartTime'] != null
          ? DateTime.parse(json['estimatedStartTime'])
          : DateTime.now(),
      estimatedEndTime: json['estimatedEndTime'] != null
          ? DateTime.parse(json['estimatedEndTime'])
          : DateTime.now(),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      totalPackages: json['totalPackages'] ?? 0,
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      totalVolume: (json['totalVolume'] ?? 0).toDouble(),
      utilizationPercent: (json['utilizationPercent'] ?? 0).toDouble(),
      baselineDistance: (json['baselineDistance'] ?? 0).toDouble(),
      carbonSaved: (json['carbonSaved'] ?? 0).toDouble(),
      emptyMilesSaved: (json['emptyMilesSaved'] ?? 0).toDouble(),
      isTSPOptimized: json['isTSPOptimized'] ?? true,
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      deliveries: (json['deliveries'] as List<dynamic>?)
          ?.map((d) => DeliveryInfo.fromJson(d))
          .toList(),
    );
  }

  // Status helpers
  bool get isPending => status == 'PENDING';
  bool get isAllocated => status == 'ALLOCATED';
  bool get isActive => status == 'ACTIVE';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'ALLOCATED':
        return 'Allocated';
      case 'ACTIVE':
        return 'Active';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// Waypoint in a route
class Waypoint {
  final double lat;
  final double lng;
  final String? address;
  final int sequence;

  Waypoint({
    required this.lat,
    required this.lng,
    this.address,
    required this.sequence,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      address: json['address'],
      sequence: json['sequence'] ?? 0,
    );
  }
}

/// Minimal delivery info in route
class DeliveryInfo {
  final String id;
  final String pickupLocation;
  final String dropLocation;
  final String status;

  DeliveryInfo({
    required this.id,
    required this.pickupLocation,
    required this.dropLocation,
    required this.status,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      id: json['id'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropLocation: json['dropLocation'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
