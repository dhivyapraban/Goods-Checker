/// Backhaul Pickup model for return trip optimization
class BackhaulModel {
  final String id;
  final String truckId;
  final String driverId;

  // Shipper details
  final String shipperId;
  final String shipperName;
  final String shipperPhone;
  final String shipperLocation;
  final double shipperLat;
  final double shipperLng;

  // Destination
  final String destinationHubId;
  final String? destinationHubName;

  // Cargo details
  final int packageCount;
  final double totalWeight;
  final double totalVolume;

  // Metrics
  final double distanceKm;
  final double carbonSavedKg;

  // Status
  final String
  status; // PROPOSED, ACCEPTED, EN_ROUTE_TO_PICKUP, PICKED_UP, DELIVERED, REJECTED

  // Timestamps
  final DateTime proposedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  BackhaulModel({
    required this.id,
    required this.truckId,
    required this.driverId,
    required this.shipperId,
    required this.shipperName,
    required this.shipperPhone,
    required this.shipperLocation,
    required this.shipperLat,
    required this.shipperLng,
    required this.destinationHubId,
    this.destinationHubName,
    required this.packageCount,
    required this.totalWeight,
    required this.totalVolume,
    required this.distanceKm,
    required this.carbonSavedKg,
    required this.status,
    required this.proposedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  factory BackhaulModel.fromJson(Map<String, dynamic> json) {
    return BackhaulModel(
      id: json['id'] ?? '',
      truckId: json['truckId'] ?? '',
      driverId: json['driverId'] ?? '',
      shipperId: json['shipperId'] ?? '',
      shipperName: json['shipperName'] ?? '',
      shipperPhone: json['shipperPhone'] ?? '',
      shipperLocation: json['shipperLocation'] ?? '',
      shipperLat: (json['shipperLat'] ?? 0).toDouble(),
      shipperLng: (json['shipperLng'] ?? 0).toDouble(),
      destinationHubId: json['destinationHubId'] ?? '',
      destinationHubName: json['destinationHubName'],
      packageCount: json['packageCount'] ?? 0,
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      totalVolume: (json['totalVolume'] ?? 0).toDouble(),
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
      carbonSavedKg: (json['carbonSavedKg'] ?? 0).toDouble(),
      status: json['status'] ?? 'PROPOSED',
      proposedAt: json['proposedAt'] != null
          ? DateTime.parse(json['proposedAt'])
          : DateTime.now(),
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
    );
  }

  // Status helpers
  bool get isProposed => status == 'PROPOSED';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isEnRouteToPickup => status == 'EN_ROUTE_TO_PICKUP';
  bool get isPickedUp => status == 'PICKED_UP';
  bool get isDelivered => status == 'DELIVERED';
  bool get isRejected => status == 'REJECTED';

  String get statusLabel {
    switch (status) {
      case 'PROPOSED':
        return 'Proposed';
      case 'ACCEPTED':
        return 'Accepted';
      case 'EN_ROUTE_TO_PICKUP':
        return 'En Route to Pickup';
      case 'PICKED_UP':
        return 'Picked Up';
      case 'DELIVERED':
        return 'Delivered';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }
}
