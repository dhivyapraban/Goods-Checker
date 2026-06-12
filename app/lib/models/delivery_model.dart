/// Delivery model for driver's assigned deliveries
class DeliveryModel {
  final String id;
  final String driverId;
  final String? truckId;
  final String? shipmentId;

  // Pickup details
  final String pickupLocation;
  final double pickupLat;
  final double pickupLng;
  final DateTime? pickupTime;

  // Drop details
  final String dropLocation;
  final double dropLat;
  final double dropLng;
  final DateTime? dropTime;
  final DateTime? estimatedETA;

  // Cargo details
  final String cargoType;
  final double cargoWeight;
  final double distanceKm;
  final String? packageId;

  // Earnings breakdown
  final double baseEarnings;
  final double marketplaceBonus;
  final double absorptionBonus;
  final double fuelSurcharge;
  final double totalEarnings;

  // Status
  final String status;
  final bool isMarketplaceLoad;

  // Timestamps
  final DateTime createdAt;
  final DateTime? completedAt;

  // Related data
  final ShipmentInfo? shipment;
  final TruckInfo? truck;

  DeliveryModel({
    required this.id,
    required this.driverId,
    this.truckId,
    this.shipmentId,
    required this.pickupLocation,
    required this.pickupLat,
    required this.pickupLng,
    this.pickupTime,
    required this.dropLocation,
    required this.dropLat,
    required this.dropLng,
    this.dropTime,
    this.estimatedETA,
    required this.cargoType,
    required this.cargoWeight,
    required this.distanceKm,
    this.packageId,
    this.baseEarnings = 0.0,
    this.marketplaceBonus = 0.0,
    this.absorptionBonus = 0.0,
    this.fuelSurcharge = 0.0,
    this.totalEarnings = 0.0,
    required this.status,
    this.isMarketplaceLoad = false,
    required this.createdAt,
    this.completedAt,
    this.shipment,
    this.truck,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      truckId: json['truckId'],
      shipmentId: json['shipmentId'],
      pickupLocation: json['pickupLocation'] ?? '',
      pickupLat: (json['pickupLat'] ?? 0).toDouble(),
      pickupLng: (json['pickupLng'] ?? 0).toDouble(),
      pickupTime: json['pickupTime'] != null
          ? DateTime.parse(json['pickupTime'])
          : null,
      dropLocation: json['dropLocation'] ?? '',
      dropLat: (json['dropLat'] ?? 0).toDouble(),
      dropLng: (json['dropLng'] ?? 0).toDouble(),
      dropTime: json['dropTime'] != null
          ? DateTime.parse(json['dropTime'])
          : null,
      estimatedETA: json['estimatedETA'] != null
          ? DateTime.parse(json['estimatedETA'])
          : null,
      cargoType: json['cargoType'] ?? '',
      cargoWeight: (json['cargoWeight'] ?? 0).toDouble(),
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
      packageId: json['packageId'],
      baseEarnings: (json['baseEarnings'] ?? 0).toDouble(),
      marketplaceBonus: (json['marketplaceBonus'] ?? 0).toDouble(),
      absorptionBonus: (json['absorptionBonus'] ?? 0).toDouble(),
      fuelSurcharge: (json['fuelSurcharge'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      isMarketplaceLoad: json['isMarketplaceLoad'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      shipment: json['shipment'] != null
          ? ShipmentInfo.fromJson(json['shipment'])
          : null,
      truck: json['truck'] != null ? TruckInfo.fromJson(json['truck']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'truckId': truckId,
      'shipmentId': shipmentId,
      'pickupLocation': pickupLocation,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'pickupTime': pickupTime?.toIso8601String(),
      'dropLocation': dropLocation,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'dropTime': dropTime?.toIso8601String(),
      'estimatedETA': estimatedETA?.toIso8601String(),
      'cargoType': cargoType,
      'cargoWeight': cargoWeight,
      'distanceKm': distanceKm,
      'packageId': packageId,
      'baseEarnings': baseEarnings,
      'marketplaceBonus': marketplaceBonus,
      'absorptionBonus': absorptionBonus,
      'fuelSurcharge': fuelSurcharge,
      'totalEarnings': totalEarnings,
      'status': status,
      'isMarketplaceLoad': isMarketplaceLoad,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Status helpers
  bool get isPending => status == 'PENDING';
  bool get isActive =>
      ['EN_ROUTE_TO_PICKUP', 'CARGO_LOADED', 'IN_TRANSIT'].contains(status);
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'EN_ROUTE_TO_PICKUP':
        return 'En Route to Pickup';
      case 'CARGO_LOADED':
        return 'Cargo Loaded';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'EN_ROUTE_TO_DROP':
        return 'En Route to Drop';
      case 'AWAITING_CONFIRMATION':
        return 'Awaiting Confirmation';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get routeString => '$pickupLocation → $dropLocation';
}

/// Minimal shipment info embedded in delivery
class ShipmentInfo {
  final String id;
  final String? cargoType;
  final double? estimatedPrice;

  ShipmentInfo({required this.id, this.cargoType, this.estimatedPrice});

  factory ShipmentInfo.fromJson(Map<String, dynamic> json) {
    return ShipmentInfo(
      id: json['id'] ?? '',
      cargoType: json['cargoType'],
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
    );
  }
}

/// Minimal truck info embedded in delivery
class TruckInfo {
  final String id;
  final String licensePlate;
  final String? model;

  TruckInfo({required this.id, required this.licensePlate, this.model});

  factory TruckInfo.fromJson(Map<String, dynamic> json) {
    return TruckInfo(
      id: json['id'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      model: json['model'],
    );
  }
}
