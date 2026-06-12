import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/synergy_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/synergy_model.dart';

import 'package:intl/intl.dart';

class SynergyOpportunitiesScreen extends StatefulWidget {
  const SynergyOpportunitiesScreen({Key? key}) : super(key: key);

  @override
  State<SynergyOpportunitiesScreen> createState() =>
      _SynergyOpportunitiesScreenState();
}

class _SynergyOpportunitiesScreenState
    extends State<SynergyOpportunitiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final truckId = authProvider.user?.trucks.firstOrNull?.id;
      if (truckId != null) {
        context.read<SynergyProvider>().searchOpportunities(truckId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Synergy Opportunities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              final truckId = authProvider.user?.trucks.firstOrNull?.id;
              if (truckId != null) {
                context.read<SynergyProvider>().searchOpportunities(truckId);
              }
            },
          ),
        ],
      ),
      body: Consumer<SynergyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.opportunities.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(provider.error!, style: AppTheme.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authProvider = context.read<AuthProvider>();
                      final truckId = authProvider.user?.trucks.firstOrNull?.id;
                      if (truckId != null) {
                        provider.searchOpportunities(truckId);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final opportunities = provider.pendingOpportunities;

          if (opportunities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 80,
                    color: AppTheme.textSecondary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Opportunities Available',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for load sharing opportunities',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authProvider = context.read<AuthProvider>();
              final truckId = authProvider.user?.trucks.firstOrNull?.id;
              if (truckId != null) {
                await provider.searchOpportunities(truckId);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: opportunities.length,
              itemBuilder: (context, index) {
                return _buildOpportunityCard(opportunities[index], provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpportunityCard(
    SynergyModel opportunity,
    SynergyProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.swap_horiz, color: AppTheme.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Load Sharing Opportunity',
                      style: AppTheme.headingSmall,
                    ),
                    Text(
                      opportunity.nearestHubName ?? 'Transfer Hub',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (opportunity.isExpiringSoon)
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
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expiring Soon',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Savings Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSavingsItem(
                    'Distance Saved',
                    '${opportunity.totalDistanceSaved.toStringAsFixed(1)} km',
                    Icons.route,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.success.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildSavingsItem(
                    'Carbon Saved',
                    '${opportunity.potentialCarbonSaved.toStringAsFixed(1)} kg',
                    Icons.eco,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Meeting Details
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Meet at ${DateFormat('h:mm a').format(opportunity.estimatedMeetTime)}',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(width: 16),
              Icon(Icons.timelapse, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${opportunity.timeWindow} min window',
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Space Requirements
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${opportunity.spaceRequiredWeight.toStringAsFixed(0)} kg, ${opportunity.spaceRequiredVolume.toStringAsFixed(0)} L',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: View details
                  },
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    final truckId = authProvider.user?.trucks.firstOrNull?.id;
                    // Determine which route this driver is on
                    final routeId = opportunity
                        .route1Id; // Simplified - in real app, check which route belongs to this driver

                    if (truckId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No truck assigned'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                      return;
                    }

                    final success = await provider.acceptOpportunity(
                      opportunityId: opportunity.id,
                      routeId: routeId,
                      truckId: truckId,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opportunity accepted!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.success, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.success,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
