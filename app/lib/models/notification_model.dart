/// Notification model for push notifications
class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'DELIVERY_ASSIGNED':
        return 'Delivery Assigned';
      case 'ABSORPTION_AVAILABLE':
        return 'Synergy Available';
      case 'ABSORPTION_ACCEPTED':
        return 'Synergy Accepted';
      case 'ABSORPTION_COMPLETED':
        return 'Synergy Completed';
      case 'BACKHAUL_OPPORTUNITY':
        return 'Backhaul Opportunity';
      case 'DELIVERY_UPDATE':
        return 'Delivery Update';
      case 'ROUTE_UPDATE':
        return 'Route Update';
      case 'SYSTEM_ALERT':
        return 'System Alert';
      case 'GPS_VERIFIED':
        return 'GPS Verified';
      case 'SHIPMENT_APPROVED':
        return 'Shipment Approved';
      case 'SHIPMENT_REJECTED':
        return 'Shipment Rejected';
      case 'PAYMENT_PROCESSED':
        return 'Payment Processed';
      case 'REGISTRATION_APPROVED':
        return 'Registration Approved';
      case 'REGISTRATION_REJECTED':
        return 'Registration Rejected';
      default:
        return type;
    }
  }
}
