/// User model matching backend Prisma schema
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String role; // DRIVER, SHIPPER, DISPATCHER
  final String status; // ON_DUTY, IN_TRANSIT, RESTING, OFF_DUTY
  final double rating;
  final int deliveriesCount;
  final double totalEarnings;
  final double weeklyEarnings;
  final double weeklyKmDriven;
  final double totalDistanceKm;
  final double totalHoursWorked;
  final String? homeBaseCity;
  final String? avatarColor;
  final String? initials;
  final String? vehicleType;
  final String? currentVehicleNo;

  // Company & Registration
  final String? courierCompanyId;
  final String registrationStatus; // PENDING, APPROVED, REJECTED, SUSPENDED
  final DateTime? registeredAt;
  final String? approvedBy;
  final String? qrCode;

  final List<TruckModel> trucks;
  final DateTime? lastActiveDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.status = 'ON_DUTY',
    this.rating = 0.0,
    this.deliveriesCount = 0,
    this.totalEarnings = 0.0,
    this.weeklyEarnings = 0.0,
    this.weeklyKmDriven = 0.0,
    this.totalDistanceKm = 0.0,
    this.totalHoursWorked = 0.0,
    this.homeBaseCity,
    this.avatarColor,
    this.initials,
    this.vehicleType,
    this.currentVehicleNo,
    this.courierCompanyId,
    this.registrationStatus = 'PENDING',
    this.registeredAt,
    this.approvedBy,
    this.qrCode,
    this.trucks = const [],
    this.lastActiveDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'DRIVER',
      status: json['status'] ?? 'ON_DUTY',
      rating: (json['rating'] ?? 0).toDouble(),
      deliveriesCount: json['deliveriesCount'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      weeklyEarnings: (json['weeklyEarnings'] ?? 0).toDouble(),
      weeklyKmDriven: (json['weeklyKmDriven'] ?? 0).toDouble(),
      totalDistanceKm: (json['totalDistanceKm'] ?? 0).toDouble(),
      totalHoursWorked: (json['totalHoursWorked'] ?? 0).toDouble(),
      homeBaseCity: json['homeBaseCity'],
      avatarColor: json['avatarColor'],
      initials: json['initials'],
      vehicleType: json['vehicleType'],
      currentVehicleNo: json['currentVehicleNo'],
      courierCompanyId: json['courierCompanyId'],
      registrationStatus: json['registrationStatus'] ?? 'PENDING',
      registeredAt: json['registeredAt'] != null
          ? DateTime.parse(json['registeredAt'])
          : null,
      approvedBy: json['approvedBy'],
      qrCode: json['qrCode'],
      trucks:
          (json['trucks'] as List<dynamic>?)
              ?.map((t) => TruckModel.fromJson(t))
              .toList() ??
          [],
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'status': status,
      'rating': rating,
      'deliveriesCount': deliveriesCount,
      'totalEarnings': totalEarnings,
      'weeklyEarnings': weeklyEarnings,
      'weeklyKmDriven': weeklyKmDriven,
      'trucks': trucks.map((t) => t.toJson()).toList(),
      'lastActiveDate': lastActiveDate?.toIso8601String(),
    };
  }

  bool get isDriver => role == 'DRIVER';
  bool get isShipper => role == 'SHIPPER';
  bool get isDispatcher => role == 'DISPATCHER';

  bool get isApproved => registrationStatus == 'APPROVED';
  bool get isPending => registrationStatus == 'PENDING';
  bool get isRejected => registrationStatus == 'REJECTED';
  bool get isSuspended => registrationStatus == 'SUSPENDED';

  String get userInitials {
    if (initials != null && initials!.isNotEmpty) return initials!;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

/// Truck model for driver's vehicles
class TruckModel {
  final String id;
  final String licensePlate;
  final String? model;
  final String? type;
  final double? capacity;
  final double? fuelLevel;
  final double? mileage;
  final double? nextService;

  final String ownerId;
  final String? courierCompanyId;

  final double? currentLat;
  final double? currentLng;

  // Capacity details
  final double maxWeight;
  final double maxVolume;
  final double currentWeight;
  final double currentVolume;

  // Fuel & emissions
  final String? fuelType; // PETROL, DIESEL, CNG, ELECTRIC
  final double? co2PerKm;
  final double? fuelConsumption;

  final bool isAvailable;
  final String registrationStatus; // PENDING, APPROVED, REJECTED, SUSPENDED
  final DateTime? registeredAt;
  final String? sourceHubId;

  final DateTime createdAt;
  final DateTime updatedAt;

  TruckModel({
    required this.id,
    required this.licensePlate,
    this.model,
    this.type,
    this.capacity,
    this.fuelLevel,
    this.mileage,
    this.nextService,
    required this.ownerId,
    this.courierCompanyId,
    this.currentLat,
    this.currentLng,
    required this.maxWeight,
    required this.maxVolume,
    this.currentWeight = 0.0,
    this.currentVolume = 0.0,
    this.fuelType,
    this.co2PerKm,
    this.fuelConsumption,
    this.isAvailable = true,
    this.registrationStatus = 'PENDING',
    this.registeredAt,
    this.sourceHubId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TruckModel.fromJson(Map<String, dynamic> json) {
    return TruckModel(
      id: json['id'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      model: json['model'],
      type: json['type'],
      capacity: (json['capacity'] as num?)?.toDouble(),
      fuelLevel: (json['fuelLevel'] as num?)?.toDouble(),
      mileage: (json['mileage'] as num?)?.toDouble(),
      nextService: (json['nextService'] as num?)?.toDouble(),
      ownerId: json['ownerId'] ?? '',
      courierCompanyId: json['courierCompanyId'],
      currentLat: (json['currentLat'] as num?)?.toDouble(),
      currentLng: (json['currentLng'] as num?)?.toDouble(),
      maxWeight: (json['maxWeight'] ?? 0).toDouble(),
      maxVolume: (json['maxVolume'] ?? 0).toDouble(),
      currentWeight: (json['currentWeight'] ?? 0).toDouble(),
      currentVolume: (json['currentVolume'] ?? 0).toDouble(),
      fuelType: json['fuelType'],
      co2PerKm: (json['co2PerKm'] as num?)?.toDouble(),
      fuelConsumption: (json['fuelConsumption'] as num?)?.toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      registrationStatus: json['registrationStatus'] ?? 'PENDING',
      registeredAt: json['registeredAt'] != null
          ? DateTime.parse(json['registeredAt'])
          : null,
      sourceHubId: json['sourceHubId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licensePlate': licensePlate,
      'model': model,
      'type': type,
      'capacity': capacity,
      'fuelLevel': fuelLevel,
      'mileage': mileage,
      'nextService': nextService,
      'ownerId': ownerId,
      'courierCompanyId': courierCompanyId,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'maxWeight': maxWeight,
      'maxVolume': maxVolume,
      'currentWeight': currentWeight,
      'currentVolume': currentVolume,
      'fuelType': fuelType,
      'co2PerKm': co2PerKm,
      'fuelConsumption': fuelConsumption,
      'isAvailable': isAvailable,
      'registrationStatus': registrationStatus,
      'registeredAt': registeredAt?.toIso8601String(),
      'sourceHubId': sourceHubId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isApproved => registrationStatus == 'APPROVED';
  bool get isPending => registrationStatus == 'PENDING';

  double get utilizationPercent {
    if (maxWeight == 0) return 0;
    return (currentWeight / maxWeight) * 100;
  }
}
