import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Status badge widget for shipments and deliveries
/// - Small chips with 8px vertical padding
/// - Color-coded: Green (Active), Orange (Pending), Gray (Completed), Red (Cancelled)
/// - Bold 12px text
class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;

  const StatusBadge({super.key, required this.status, this.customLabel});

  @override
  Widget build(BuildContext context) {
    final badgeData = _getStatusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: badgeData.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeData.color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        customLabel ?? badgeData.label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ).copyWith(color: badgeData.color),
      ),
    );
  }

  _StatusData _getStatusData(String status) {
    final statusUpper = status.toUpperCase();

    // Active/In Progress - Green
    if (statusUpper == 'IN_TRANSIT' ||
        statusUpper == 'ACTIVE' ||
        statusUpper == 'EN_ROUTE_TO_PICKUP' ||
        statusUpper == 'CARGO_LOADED' ||
        statusUpper == 'DRIVER_ACCEPTED' ||
        statusUpper == 'DISPATCHER_APPROVED') {
      return _StatusData(
        color: AppTheme.statusActive,
        label: _getDisplayLabel(statusUpper),
      );
    }

    // Pending/Awaiting - Orange
    if (statusUpper == 'PENDING' ||
        statusUpper == 'AWAITING_DISPATCHER' ||
        statusUpper == 'DRIVER_NOTIFIED') {
      return _StatusData(
        color: AppTheme.statusPending,
        label: _getDisplayLabel(statusUpper),
      );
    }

    // Completed - Gray
    if (statusUpper == 'COMPLETED' || statusUpper == 'DELIVERED') {
      return _StatusData(color: AppTheme.statusCompleted, label: 'Completed');
    }

    // Cancelled/Rejected - Red
    if (statusUpper == 'CANCELLED' ||
        statusUpper == 'DRIVER_REJECTED' ||
        statusUpper == 'DISPATCHER_REJECTED') {
      return _StatusData(
        color: AppTheme.statusCancelled,
        label: _getDisplayLabel(statusUpper),
      );
    }

    // Default - Gray with original status
    return _StatusData(
      color: AppTheme.textSecondary,
      label: _getDisplayLabel(statusUpper),
    );
  }

  String _getDisplayLabel(String status) {
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
        return 'Driver Declined';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'EN_ROUTE_TO_PICKUP':
        return 'En Route';
      case 'CARGO_LOADED':
        return 'Loaded';
      case 'COMPLETED':
        return 'Completed';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      case 'ACTIVE':
        return 'Active';
      default:
        return status
            .split('_')
            .map((word) => word[0] + word.substring(1).toLowerCase())
            .join(' ');
    }
  }
}

class _StatusData {
  final Color color;
  final String label;

  _StatusData({required this.color, required this.label});
}
