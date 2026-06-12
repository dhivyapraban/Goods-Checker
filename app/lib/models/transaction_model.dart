/// Transaction model for driver earnings
class TransactionModel {
  final String id;
  final String driverId;
  final String? deliveryId;
  final double amount;
  final String type;
  final String description;
  final String? route;
  final DateTime createdAt;
  final TransactionDeliveryInfo? delivery;

  TransactionModel({
    required this.id,
    required this.driverId,
    this.deliveryId,
    required this.amount,
    required this.type,
    required this.description,
    this.route,
    required this.createdAt,
    this.delivery,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      deliveryId: json['deliveryId'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      route: json['route'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      delivery: json['delivery'] != null
          ? TransactionDeliveryInfo.fromJson(json['delivery'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'deliveryId': deliveryId,
      'amount': amount,
      'type': type,
      'description': description,
      'route': route,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'BASE_DELIVERY':
        return 'Base Delivery';
      case 'MARKETPLACE_BONUS':
        return 'Marketplace Bonus';
      case 'ABSORPTION_BONUS':
        return 'Absorption Bonus';
      case 'FUEL_SURCHARGE':
        return 'Fuel Surcharge';
      case 'TOLL_REIMBURSEMENT':
        return 'Toll Reimbursement';
      case 'PENALTY':
        return 'Penalty';
      case 'BONUS':
        return 'Bonus';
      case 'ADJUSTMENT':
        return 'Adjustment';
      default:
        return type;
    }
  }

  bool get isPositive => type != 'PENALTY';
}

/// Minimal delivery info in transaction
class TransactionDeliveryInfo {
  final String pickupLocation;
  final String dropLocation;
  final String? cargoType;
  final DateTime? completedAt;

  TransactionDeliveryInfo({
    required this.pickupLocation,
    required this.dropLocation,
    this.cargoType,
    this.completedAt,
  });

  factory TransactionDeliveryInfo.fromJson(Map<String, dynamic> json) {
    return TransactionDeliveryInfo(
      pickupLocation: json['pickupLocation'] ?? '',
      dropLocation: json['dropLocation'] ?? '',
      cargoType: json['cargoType'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  String get route => '$pickupLocation → $dropLocation';
}

/// Weekly summary model
class WeeklySummaryModel {
  final double earnings;
  final double distance;
  final double totalEarnings;
  final double totalDistance;
  final DateTime resetDate;
  final Map<String, double> dailyBreakdown;

  WeeklySummaryModel({
    required this.earnings,
    required this.distance,
    required this.totalEarnings,
    required this.totalDistance,
    required this.resetDate,
    required this.dailyBreakdown,
  });

  factory WeeklySummaryModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final daily = json['dailyBreakdown'] as Map<String, dynamic>? ?? {};

    return WeeklySummaryModel(
      earnings: (summary['earnings'] ?? 0).toDouble(),
      distance: (summary['distance'] ?? 0).toDouble(),
      totalEarnings: (summary['totalEarnings'] ?? 0).toDouble(),
      totalDistance: (summary['totalDistance'] ?? 0).toDouble(),
      resetDate: summary['resetDate'] != null
          ? DateTime.parse(summary['resetDate'])
          : DateTime.now(),
      dailyBreakdown: daily.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}
