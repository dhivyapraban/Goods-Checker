/// E-Way Bill model for logistics compliance
class EwayBillModel {
  final String id;
  final String billNumber;
  final String status; // GENERATED, UPDATED, CANCELLED, EXPIRED
  final String? deliveryId;
  final String? shipmentId;

  // Bill details
  final String fromPlace;
  final String toPlace;
  final double distanceKm;
  final String vehicleNumber;
  final String transporter;

  // Cargo details
  final String cargoDescription;
  final double cargoWeight;
  final double cargoValue;
  final String hsnCode;

  // Validity
  final DateTime generatedAt;
  final DateTime validUntil;
  final DateTime? updatedAt;

  // PDF
  final String? pdfUrl;
  final bool canDownload;

  EwayBillModel({
    required this.id,
    required this.billNumber,
    required this.status,
    this.deliveryId,
    this.shipmentId,
    required this.fromPlace,
    required this.toPlace,
    required this.distanceKm,
    required this.vehicleNumber,
    required this.transporter,
    required this.cargoDescription,
    required this.cargoWeight,
    required this.cargoValue,
    this.hsnCode = '',
    required this.generatedAt,
    required this.validUntil,
    this.updatedAt,
    this.pdfUrl,
    this.canDownload = true,
  });

  factory EwayBillModel.fromJson(Map<String, dynamic> json) {
    return EwayBillModel(
      id: json['id'] ?? '',
      billNumber: json['billNumber'] ?? json['ewbNumber'] ?? '',
      status: json['status'] ?? 'GENERATED',
      deliveryId: json['deliveryId'],
      shipmentId: json['shipmentId'],
      fromPlace: json['fromPlace'] ?? json['pickupLocation'] ?? '',
      toPlace: json['toPlace'] ?? json['dropLocation'] ?? '',
      distanceKm: (json['distanceKm'] ?? json['distance'] ?? 0).toDouble(),
      vehicleNumber: json['vehicleNumber'] ?? json['vehicleNo'] ?? '',
      transporter: json['transporter'] ?? json['transporterName'] ?? '',
      cargoDescription: json['cargoDescription'] ?? json['productName'] ?? '',
      cargoWeight: (json['cargoWeight'] ?? json['quantity'] ?? 0).toDouble(),
      cargoValue: (json['cargoValue'] ?? json['taxableValue'] ?? 0).toDouble(),
      hsnCode: json['hsnCode'] ?? '',
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'])
          : (json['createdAt'] != null
                ? DateTime.parse(json['createdAt'])
                : DateTime.now()),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : (json['validTill'] != null
                ? DateTime.parse(json['validTill'])
                : DateTime.now().add(const Duration(days: 1))),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      pdfUrl: json['pdfUrl'] ?? json['downloadUrl'],
      canDownload: json['canDownload'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'billNumber': billNumber,
      'status': status,
      'deliveryId': deliveryId,
      'shipmentId': shipmentId,
      'fromPlace': fromPlace,
      'toPlace': toPlace,
      'distanceKm': distanceKm,
      'vehicleNumber': vehicleNumber,
      'transporter': transporter,
      'cargoDescription': cargoDescription,
      'cargoWeight': cargoWeight,
      'cargoValue': cargoValue,
      'hsnCode': hsnCode,
      'generatedAt': generatedAt.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'pdfUrl': pdfUrl,
      'canDownload': canDownload,
    };
  }

  // Status helpers
  bool get isActive => status == 'GENERATED' || status == 'UPDATED';
  bool get isExpired =>
      status == 'EXPIRED' || DateTime.now().isAfter(validUntil);
  bool get isCancelled => status == 'CANCELLED';

  String get statusLabel {
    switch (status) {
      case 'GENERATED':
        return 'Generated';
      case 'UPDATED':
        return 'Updated';
      case 'CANCELLED':
        return 'Cancelled';
      case 'EXPIRED':
        return 'Expired';
      default:
        return status;
    }
  }

  // Formatted route
  String get routeString => '$fromPlace → $toPlace';

  // Formatted value
  String get formattedValue => '₹${cargoValue.toStringAsFixed(2)}';

  // Formatted weight
  String get formattedWeight => '${cargoWeight.toStringAsFixed(1)} kg';

  // Validity status
  String get validityStatus {
    if (isExpired) return 'Expired';
    final remaining = validUntil.difference(DateTime.now());
    if (remaining.inHours < 1) return 'Expires in ${remaining.inMinutes}m';
    if (remaining.inDays < 1) return 'Expires in ${remaining.inHours}h';
    return 'Valid for ${remaining.inDays}d';
  }
}
