import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/shipment_model.dart';
import '../../providers/shipment_provider.dart';
import 'shipment_tracking_screen.dart';

/// Shipment details screen
class ShipmentDetailsScreen extends StatelessWidget {
  final ShipmentModel shipment;

  const ShipmentDetailsScreen({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shipment #${shipment.id.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Share
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 20),

            // Route Card
            _buildRouteCard(),
            const SizedBox(height: 20),

            // Cargo Card
            _buildCargoCard(),
            const SizedBox(height: 20),

            // Pricing Card
            _buildPricingCard(),
            const SizedBox(height: 20),

            // Driver Card (if assigned)
            if (shipment.delivery?.driver != null) ...[
              _buildDriverCard(context),
              const SizedBox(height: 20),
            ],

            // Timeline
            _buildTimeline(),
            const SizedBox(height: 20),

            // Cancel button (if pending)
            if (shipment.canCancel) _buildCancelButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final color = AppTheme.getStatusColor(shipment.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_getStatusIcon(), color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipment.statusLabel,
                  style: AppTheme.headingSmall.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(_getStatusDescription(), style: AppTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (shipment.status) {
      case 'PENDING':
        return Icons.pending_outlined;
      case 'DISPATCHED':
        return Icons.local_shipping_outlined;
      case 'IN_TRANSIT':
        return Icons.local_shipping;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusDescription() {
    switch (shipment.status) {
      case 'PENDING':
        return 'Waiting for dispatcher assignment';
      case 'DISPATCHED':
        return 'Driver has been assigned';
      case 'IN_TRANSIT':
        return 'Your shipment is on the way';
      case 'DELIVERED':
        return 'Shipment delivered successfully';
      case 'CANCELLED':
        return 'This shipment was cancelled';
      default:
        return '';
    }
  }

  Widget _buildRouteCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route Details', style: AppTheme.labelLarge),
            const SizedBox(height: 16),

            // Pickup
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      color: AppTheme.surfaceLight,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PICKUP', style: AppTheme.caption),
                      const SizedBox(height: 4),
                      Text(
                        shipment.pickupLocation ?? 'Pickup location',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Drop
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DROP', style: AppTheme.caption),
                      const SizedBox(height: 4),
                      Text(
                        shipment.dropLocation ?? 'Drop location',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCargoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cargo Details', style: AppTheme.labelLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCargoItem(
                    Icons.category_outlined,
                    'Type',
                    shipment.cargoType ?? 'General',
                  ),
                ),
                if (shipment.cargoWeight != null)
                  Expanded(
                    child: _buildCargoItem(
                      Icons.scale_outlined,
                      'Weight',
                      '${shipment.cargoWeight!.toStringAsFixed(1)} T',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCargoItem(Icons.priority_high, 'Priority', shipment.priority),
            if (shipment.specialInstructions != null &&
                shipment.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCargoItem(
                Icons.note_outlined,
                'Instructions',
                shipment.specialInstructions!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCargoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.caption),
            Text(value, style: AppTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pricing', style: AppTheme.labelLarge),
            const SizedBox(height: 16),
            if (shipment.estimatedPrice != null)
              _buildPriceRow(
                'Estimated Price',
                '₹${NumberFormat('#,##,###').format(shipment.estimatedPrice)}',
              ),
            if (shipment.finalPrice != null) ...[
              const SizedBox(height: 8),
              _buildPriceRow(
                'Final Price',
                '₹${NumberFormat('#,##,###').format(shipment.finalPrice)}',
                isFinal: true,
              ),
            ],
            if (shipment.estimatedPrice == null && shipment.finalPrice == null)
              const Text(
                'Pricing will be calculated soon',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isFinal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium),
        Text(
          value,
          style: isFinal
              ? AppTheme.headingSmall.copyWith(color: AppTheme.primary)
              : AppTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildDriverCard(BuildContext context) {
    final driver = shipment.delivery!.driver!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned Driver', style: AppTheme.labelLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    driver.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name, style: AppTheme.bodyLarge),
                      if (driver.phone != null)
                        Text(driver.phone!, style: AppTheme.caption),
                    ],
                  ),
                ),
                if (driver.rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          driver.rating!.toStringAsFixed(1),
                          style: AppTheme.labelLarge.copyWith(
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Call driver
                    },
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ShipmentTrackingScreen(shipment: shipment),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Track'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipment Timeline', style: AppTheme.labelLarge),
            const SizedBox(height: 16),
            _buildTimelineItem('Created', true, shipment.createdAt),
            _buildTimelineItem(
              'Dispatched',
              shipment.dispatchedAt != null,
              shipment.dispatchedAt,
            ),
            _buildTimelineItem(
              'In Transit',
              shipment.isInTransit || shipment.isCompleted,
              null,
            ),
            _buildTimelineItem(
              'Delivered',
              shipment.isCompleted,
              shipment.completedAt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String label, bool completed, DateTime? time) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: completed ? AppTheme.success : AppTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check : Icons.circle_outlined,
                size: 14,
                color: completed ? Colors.white : AppTheme.textMuted,
              ),
            ),
            if (label != 'Delivered')
              Container(
                width: 2,
                height: 24,
                color: completed ? AppTheme.success : AppTheme.surfaceLight,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  color: completed ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
              if (time != null)
                Text(
                  DateFormat('MMM dd, hh:mm a').format(time),
                  style: AppTheme.caption,
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showCancelDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: const BorderSide(color: AppTheme.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Cancel Shipment'),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cancel Shipment?'),
        content: const Text(
          'Are you sure you want to cancel this shipment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<ShipmentProvider>();
              final success = await provider.cancelShipment(shipment.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shipment cancelled'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
