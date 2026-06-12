/// Shipment model for shipper's shipments
class ShipmentModel {
  final String id;
  final String shipperId;
  final String? dispatcherId;

  // Pickup details
  final String? pickupLocation;
  final double? pickupLat;
  final double? pickupLng;
  final DateTime? pickupTime;

  // Drop details
  final String? dropLocation;
  final double? dropLat;
  final double? dropLng;
  final DateTime? dropTime;

  // Cargo details
  final String? cargoType;
  final double? cargoWeight;
  final double? cargoVolume;
  final String? specialInstructions;

  // Pricing
  final double? estimatedPrice;
  final double? finalPrice;

  // Status
  final String status;
  final String priority;
  final bool isMarketplaceLoad;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dispatchedAt;
  final DateTime? completedAt;
  final DateTime? dispatcherApprovedAt;
  final DateTime? dispatcherRejectedAt;
  final String? rejectionReason;

  // Related data
  final ShipperInfo? shipper;
  final DispatcherInfo? dispatcher;
  final DeliveryInfo? delivery;

  ShipmentModel({
    required this.id,
    required this.shipperId,
    this.dispatcherId,
    this.pickupLocation,
    this.pickupLat,
    this.pickupLng,
    this.pickupTime,
    this.dropLocation,
    this.dropLat,
    this.dropLng,
    this.dropTime,
    this.cargoType,
    this.cargoWeight,
    this.cargoVolume,
    this.specialInstructions,
    this.estimatedPrice,
    this.finalPrice,
    required this.status,
    this.priority = 'LOW',
    this.isMarketplaceLoad = false,
    required this.createdAt,
    required this.updatedAt,
    this.dispatchedAt,
    this.completedAt,
    this.dispatcherApprovedAt,
    this.dispatcherRejectedAt,
    this.rejectionReason,
    this.shipper,
    this.dispatcher,
    this.delivery,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: json['id'] ?? '',
      shipperId: json['shipperId'] ?? '',
      dispatcherId: json['dispatcherId'],
      pickupLocation: json['pickupLocation'],
      pickupLat: (json['pickupLat'] as num?)?.toDouble(),
      pickupLng: (json['pickupLng'] as num?)?.toDouble(),
      pickupTime: json['pickupTime'] != null
          ? DateTime.parse(json['pickupTime'])
          : null,
      dropLocation: json['dropLocation'],
      dropLat: (json['dropLat'] as num?)?.toDouble(),
      dropLng: (json['dropLng'] as num?)?.toDouble(),
      dropTime: json['dropTime'] != null
          ? DateTime.parse(json['dropTime'])
          : null,
      cargoType: json['cargoType'],
      cargoWeight: (json['cargoWeight'] as num?)?.toDouble(),
      cargoVolume: (json['cargoVolume'] as num?)?.toDouble(),
      specialInstructions: json['specialInstructions'],
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      status: json['status'] ?? 'PENDING',
      priority: json['priority'] ?? 'LOW',
      isMarketplaceLoad: json['isMarketplaceLoad'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      dispatchedAt: json['dispatchedAt'] != null
          ? DateTime.parse(json['dispatchedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      dispatcherApprovedAt: json['dispatcherApprovedAt'] != null
          ? DateTime.parse(json['dispatcherApprovedAt'])
          : null,
      dispatcherRejectedAt: json['dispatcherRejectedAt'] != null
          ? DateTime.parse(json['dispatcherRejectedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      shipper: json['shipper'] != null
          ? ShipperInfo.fromJson(json['shipper'])
          : null,
      dispatcher: json['dispatcher'] != null
          ? DispatcherInfo.fromJson(json['dispatcher'])
          : null,
      delivery: json['delivery'] != null
          ? DeliveryInfo.fromJson(json['delivery'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipperId': shipperId,
      'dispatcherId': dispatcherId,
      'pickupLocation': pickupLocation,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'pickupTime': pickupTime?.toIso8601String(),
      'dropLocation': dropLocation,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'dropTime': dropTime?.toIso8601String(),
      'cargoType': cargoType,
      'cargoWeight': cargoWeight,
      'specialInstructions': specialInstructions,
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'status': status,
      'priority': priority,
      'isMarketplaceLoad': isMarketplaceLoad,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Status helpers
  bool get isPending => status == 'PENDING' || status == 'AWAITING_DISPATCHER';
  bool get isInTransit => status == 'IN_TRANSIT' || status == 'DRIVER_ACCEPTED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get canCancel => isPending;

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'AWAITING_DISPATCHER':
        return 'Awaiting Approval';
      case 'DISPATCHER_APPROVED':
        return 'Approved';
      case 'DISPATCHER_REJECTED':
        return 'Rejected';
      case 'DRIVER_NOTIFIED':
        return 'Finding Driver';
      case 'DRIVER_ACCEPTED':
        return 'Driver Assigned';
      case 'DRIVER_REJECTED':
        return 'Driver Rejected';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get routeString {
    final pickup = pickupLocation ?? 'Unknown';
    final drop = dropLocation ?? 'Unknown';
    return '$pickup → $drop';
  }

  double get displayPrice => finalPrice ?? estimatedPrice ?? 0.0;
}

/// Minimal shipper info embedded in shipment
class ShipperInfo {
  final String name;
  final String? phone;

  ShipperInfo({required this.name, this.phone});

  factory ShipperInfo.fromJson(Map<String, dynamic> json) {
    return ShipperInfo(name: json['name'] ?? '', phone: json['phone']);
  }
}

/// Minimal dispatcher info embedded in shipment
class DispatcherInfo {
  final String name;

  DispatcherInfo({required this.name});

  factory DispatcherInfo.fromJson(Map<String, dynamic> json) {
    return DispatcherInfo(name: json['name'] ?? '');
  }
}

/// Minimal delivery info embedded in shipment (for tracking)
class DeliveryInfo {
  final String id;
  final String status;
  final DriverInfo? driver;

  DeliveryInfo({required this.id, required this.status, this.driver});

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      driver: json['driver'] != null
          ? DriverInfo.fromJson(json['driver'])
          : null,
    );
  }
}

/// Driver info for tracking
class DriverInfo {
  final String name;
  final double? rating;
  final String? phone;

  DriverInfo({required this.name, this.rating, this.phone});

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      phone: json['phone'],
    );
  }
}
