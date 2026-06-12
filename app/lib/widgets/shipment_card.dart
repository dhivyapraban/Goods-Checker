import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/shipment_model.dart';
import 'status_badge.dart';

/// Shipment card widget for shipper app
class ShipmentCard extends StatelessWidget {
  final ShipmentModel shipment;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const ShipmentCard({
    super.key,
    required this.shipment,
    this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Shipment #${shipment.id.substring(0, 8)}',
                      style: AppTheme.labelLarge,
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),

              // Route
              _buildRouteInfo(),
              const SizedBox(height: 12),

              // Details row
              Row(
                children: [
                  _buildInfoChip(
                    Icons.inventory_2_outlined,
                    shipment.cargoType ?? 'General',
                  ),
                  const SizedBox(width: 12),
                  if (shipment.cargoWeight != null)
                    _buildInfoChip(
                      Icons.scale,
                      '${shipment.cargoWeight!.toStringAsFixed(1)} T',
                    ),
                  const Spacer(),
                  Text(
                    '₹${NumberFormat('#,##,###').format(shipment.displayPrice)}',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),

              // Driver info (if assigned)
              if (shipment.delivery?.driver != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shipment.delivery!.driver!.name,
                            style: AppTheme.bodyMedium,
                          ),
                          if (shipment.delivery!.driver!.rating != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: AppTheme.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  shipment.delivery!.driver!.rating!
                                      .toStringAsFixed(1),
                                  style: AppTheme.caption,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (shipment.isInTransit)
                      TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.location_on, size: 16),
                        label: const Text('Track'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                  ],
                ),
              ],

              // Cancel button for pending shipments
              if (shipment.canCancel && onCancel != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    child: const Text('Cancel Shipment'),
                  ),
                ),
              ],

              // Date
              const SizedBox(height: 8),
              Text(
                'Created ${DateFormat('MMM dd, yyyy • hh:mm a').format(shipment.createdAt)}',
                style: AppTheme.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return StatusBadge(status: shipment.status);
  }

  Widget _buildRouteInfo() {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 24, color: AppTheme.surfaceLight),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shipment.pickupLocation ?? 'Pickup location',
                style: AppTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                shipment.dropLocation ?? 'Drop location',
                style: AppTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
