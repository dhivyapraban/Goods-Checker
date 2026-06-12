/// Synergy/Absorption Opportunity model for load sharing
class SynergyModel {
  final String id;
  final String route1Id;
  final String route2Id;

  // Overlap details
  final double overlapDistanceKm;
  final DateTime overlapStartTime;
  final DateTime overlapEndTime;

  // Hub details
  final String nearestHubId;
  final String? nearestHubName;
  final String? overlapPolyline;
  final double overlapCenterLat;
  final double overlapCenterLng;

  // Meeting details
  final DateTime estimatedMeetTime;
  final int timeWindow; // minutes

  // Eligible deliveries
  final String eligibleDeliveryIds; // comma-separated

  // Distance savings
  final double truck1DistanceBefore;
  final double truck1DistanceAfter;
  final double truck2DistanceBefore;
  final double truck2DistanceAfter;
  final double totalDistanceSaved;
  final double potentialCarbonSaved;

  // Space requirements
  final double spaceRequiredVolume;
  final double spaceRequiredWeight;
  final double truck1SpaceAvailable;
  final double truck2SpaceAvailable;

  // Status
  final String
  status; // PENDING, ACCEPTED_BY_ROUTE1, ACCEPTED_BY_ROUTE2, BOTH_ACCEPTED, etc.

  // Timestamps
  final DateTime proposedAt;
  final DateTime expiresAt;
  final DateTime? acceptedByRoute1At;
  final DateTime? acceptedByRoute2At;
  final DateTime createdAt;

  SynergyModel({
    required this.id,
    required this.route1Id,
    required this.route2Id,
    required this.overlapDistanceKm,
    required this.overlapStartTime,
    required this.overlapEndTime,
    required this.nearestHubId,
    this.nearestHubName,
    this.overlapPolyline,
    required this.overlapCenterLat,
    required this.overlapCenterLng,
    required this.estimatedMeetTime,
    required this.timeWindow,
    required this.eligibleDeliveryIds,
    required this.truck1DistanceBefore,
    required this.truck1DistanceAfter,
    required this.truck2DistanceBefore,
    required this.truck2DistanceAfter,
    required this.totalDistanceSaved,
    required this.potentialCarbonSaved,
    required this.spaceRequiredVolume,
    required this.spaceRequiredWeight,
    required this.truck1SpaceAvailable,
    required this.truck2SpaceAvailable,
    required this.status,
    required this.proposedAt,
    required this.expiresAt,
    this.acceptedByRoute1At,
    this.acceptedByRoute2At,
    required this.createdAt,
  });

  factory SynergyModel.fromJson(Map<String, dynamic> json) {
    return SynergyModel(
      id: json['id'] ?? '',
      route1Id: json['route1Id'] ?? '',
      route2Id: json['route2Id'] ?? '',
      overlapDistanceKm: (json['overlapDistanceKm'] ?? 0).toDouble(),
      overlapStartTime: json['overlapStartTime'] != null
          ? DateTime.parse(json['overlapStartTime'])
          : DateTime.now(),
      overlapEndTime: json['overlapEndTime'] != null
          ? DateTime.parse(json['overlapEndTime'])
          : DateTime.now(),
      nearestHubId: json['nearestHubId'] ?? '',
      nearestHubName: json['nearestHubName'],
      overlapPolyline: json['overlapPolyline'],
      overlapCenterLat: (json['overlapCenterLat'] ?? 0).toDouble(),
      overlapCenterLng: (json['overlapCenterLng'] ?? 0).toDouble(),
      estimatedMeetTime: json['estimatedMeetTime'] != null
          ? DateTime.parse(json['estimatedMeetTime'])
          : DateTime.now(),
      timeWindow: json['timeWindow'] ?? 30,
      eligibleDeliveryIds: json['eligibleDeliveryIds'] ?? '',
      truck1DistanceBefore: (json['truck1DistanceBefore'] ?? 0).toDouble(),
      truck1DistanceAfter: (json['truck1DistanceAfter'] ?? 0).toDouble(),
      truck2DistanceBefore: (json['truck2DistanceBefore'] ?? 0).toDouble(),
      truck2DistanceAfter: (json['truck2DistanceAfter'] ?? 0).toDouble(),
      totalDistanceSaved: (json['totalDistanceSaved'] ?? 0).toDouble(),
      potentialCarbonSaved: (json['potentialCarbonSaved'] ?? 0).toDouble(),
      spaceRequiredVolume: (json['spaceRequiredVolume'] ?? 0).toDouble(),
      spaceRequiredWeight: (json['spaceRequiredWeight'] ?? 0).toDouble(),
      truck1SpaceAvailable: (json['truck1SpaceAvailable'] ?? 0).toDouble(),
      truck2SpaceAvailable: (json['truck2SpaceAvailable'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      proposedAt: json['proposedAt'] != null
          ? DateTime.parse(json['proposedAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(hours: 1)),
      acceptedByRoute1At: json['acceptedByRoute1At'] != null
          ? DateTime.parse(json['acceptedByRoute1At'])
          : null,
      acceptedByRoute2At: json['acceptedByRoute2At'] != null
          ? DateTime.parse(json['acceptedByRoute2At'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // Status helpers
  bool get isPending => status == 'PENDING';
  bool get isAcceptedByRoute1 => status == 'ACCEPTED_BY_ROUTE1';
  bool get isAcceptedByRoute2 => status == 'ACCEPTED_BY_ROUTE2';
  bool get isBothAccepted => status == 'BOTH_ACCEPTED';
  bool get isActive => status == 'ACTIVE';
  bool get isCompleted => status == 'COMPLETED';
  bool get isExpired => status == 'EXPIRED';
  bool get isRejected => status == 'REJECTED';

  bool get isExpiringSoon {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);
    return diff.inMinutes < 15 && diff.inMinutes > 0;
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'ACCEPTED_BY_ROUTE1':
        return 'Partially Accepted';
      case 'ACCEPTED_BY_ROUTE2':
        return 'Partially Accepted';
      case 'BOTH_ACCEPTED':
        return 'Both Accepted';
      case 'ACTIVE':
        return 'Active';
      case 'COMPLETED':
        return 'Completed';
      case 'EXPIRED':
        return 'Expired';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }
}
