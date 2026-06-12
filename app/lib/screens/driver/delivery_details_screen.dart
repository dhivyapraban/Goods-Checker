import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/custom_button.dart';
import 'navigation_screen.dart';

/// Delivery details screen
class DeliveryDetailsScreen extends StatelessWidget {
  final DeliveryModel delivery;

  const DeliveryDetailsScreen({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip #${delivery.id.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Share delivery details
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

            // Cargo Details
            _buildCargoCard(),
            const SizedBox(height: 20),

            // Earnings Breakdown
            _buildEarningsCard(),
            const SizedBox(height: 20),

            // Status Timeline
            _buildTimeline(),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final color = AppTheme.getStatusColor(delivery.status);

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
                  delivery.statusLabel,
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
    switch (delivery.status) {
      case 'PENDING':
        return Icons.pending_outlined;
      case 'EN_ROUTE_TO_PICKUP':
        return Icons.directions_car;
      case 'CARGO_LOADED':
        return Icons.check_box;
      case 'IN_TRANSIT':
        return Icons.local_shipping;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusDescription() {
    switch (delivery.status) {
      case 'PENDING':
        return 'Accept this delivery to start';
      case 'EN_ROUTE_TO_PICKUP':
        return 'Navigate to pickup location';
      case 'CARGO_LOADED':
        return 'Proceed to drop location';
      case 'IN_TRANSIT':
        return 'Delivery in progress';
      case 'COMPLETED':
        return 'Delivery completed successfully';
      case 'CANCELLED':
        return 'This delivery was cancelled';
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
                      height: 50,
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
                      Text(delivery.pickupLocation, style: AppTheme.bodyMedium),
                      if (delivery.pickupTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM dd, hh:mm a',
                          ).format(delivery.pickupTime!),
                          style: AppTheme.bodySmall,
                        ),
                      ],
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
                      Text(delivery.dropLocation, style: AppTheme.bodyMedium),
                      if (delivery.estimatedETA != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'ETA: ${DateFormat('MMM dd, hh:mm a').format(delivery.estimatedETA!)}',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    'Distance',
                    '${delivery.distanceKm.toStringAsFixed(1)} km',
                  ),
                  Container(width: 1, height: 30, color: AppTheme.surface),
                  _buildInfoItem(
                    'Est. Time',
                    '${(delivery.distanceKm / 40 * 60).round()} min',
                  ),
                ],
              ),
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
                    delivery.cargoType,
                  ),
                ),
                Expanded(
                  child: _buildCargoItem(
                    Icons.scale_outlined,
                    'Weight',
                    '${delivery.cargoWeight.toStringAsFixed(1)} Tonnes',
                  ),
                ),
              ],
            ),
            if (delivery.packageId != null) ...[
              const SizedBox(height: 12),
              _buildCargoItem(Icons.qr_code, 'Package ID', delivery.packageId!),
            ],
            if (delivery.isMarketplaceLoad) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.info, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Marketplace Load - Bonus earnings included!',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.info,
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildEarningsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Earnings Breakdown', style: AppTheme.labelLarge),
            const SizedBox(height: 16),
            _buildEarningsRow('Base Earnings', delivery.baseEarnings),
            if (delivery.marketplaceBonus > 0)
              _buildEarningsRow(
                'Marketplace Bonus',
                delivery.marketplaceBonus,
                isBonus: true,
              ),
            if (delivery.absorptionBonus > 0)
              _buildEarningsRow(
                'Absorption Bonus',
                delivery.absorptionBonus,
                isBonus: true,
              ),
            if (delivery.fuelSurcharge > 0)
              _buildEarningsRow('Fuel Surcharge', delivery.fuelSurcharge),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Earnings', style: AppTheme.labelLarge),
                Text(
                  '₹${NumberFormat('#,##,###').format(delivery.totalEarnings)}',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsRow(
    String label,
    double amount, {
    bool isBonus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: AppTheme.bodyMedium),
              if (isBonus) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 14, color: AppTheme.warning),
              ],
            ],
          ),
          Text(
            '₹${NumberFormat('#,##,###').format(amount)}',
            style: AppTheme.bodyMedium.copyWith(
              color: isBonus ? AppTheme.success : AppTheme.textPrimary,
            ),
          ),
        ],
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
            Text('Delivery Timeline', style: AppTheme.labelLarge),
            const SizedBox(height: 16),
            _buildTimelineItem('Assigned', true, delivery.createdAt),
            _buildTimelineItem('Accepted', delivery.status != 'PENDING', null),
            _buildTimelineItem(
              'Picked Up',
              delivery.pickupTime != null,
              delivery.pickupTime,
            ),
            _buildTimelineItem(
              'In Transit',
              delivery.isActive || delivery.isCompleted,
              null,
            ),
            _buildTimelineItem(
              'Delivered',
              delivery.isCompleted,
              delivery.completedAt,
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

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTheme.labelLarge),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.caption),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final provider = context.read<DeliveryProvider>();

    switch (delivery.status) {
      case 'PENDING':
        return Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Reject',
                isOutlined: true,
                onPressed: () => _showRejectDialog(context, provider),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'Accept',
                onPressed: () async {
                  final success = await provider.acceptDelivery(delivery.id);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery accepted!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        );

      case 'EN_ROUTE_TO_PICKUP':
        return Column(
          children: [
            CustomButton(
              text: 'Start Navigation',
              icon: Icons.navigation,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NavigationScreen(delivery: delivery),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Mark Cargo Picked Up',
              isOutlined: true,
              onPressed: () async {
                final success = await provider.pickupCargo(delivery.id);
                if (success && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );

      case 'CARGO_LOADED':
      case 'IN_TRANSIT':
        return Column(
          children: [
            CustomButton(
              text: 'Navigate to Drop',
              icon: Icons.navigation,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NavigationScreen(delivery: delivery),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Mark Delivered',
              isOutlined: true,
              onPressed: () => _showCompleteDialog(context, provider),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _showRejectDialog(BuildContext context, DeliveryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Reject Delivery?'),
        content: const Text(
          'Are you sure you want to reject this delivery? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.rejectDelivery(delivery.id);
              if (success && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, DeliveryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Complete Delivery?'),
        content: const Text(
          'Confirm that the cargo has been delivered successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.completeDelivery(delivery.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delivery completed! Earnings added.'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
