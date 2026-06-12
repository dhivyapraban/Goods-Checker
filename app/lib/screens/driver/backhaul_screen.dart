import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/backhaul_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/backhaul_model.dart';

class BackhaulScreen extends StatefulWidget {
  const BackhaulScreen({Key? key}) : super(key: key);

  @override
  State<BackhaulScreen> createState() => _BackhaulScreenState();
}

class _BackhaulScreenState extends State<BackhaulScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final truckId = authProvider.user?.trucks.firstOrNull?.id;
      if (truckId != null) {
        context.read<BackhaulProvider>().fetchOpportunities(truckId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Backhaul Opportunities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              final truckId = authProvider.user?.trucks.firstOrNull?.id;
              if (truckId != null) {
                context.read<BackhaulProvider>().fetchOpportunities(truckId);
              }
            },
          ),
        ],
      ),
      body: Consumer<BackhaulProvider>(
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
                        provider.fetchOpportunities(truckId);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final opportunities = provider.proposedOpportunities;

          if (opportunities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.u_turn_left,
                    size: 80,
                    color: AppTheme.textSecondary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Return Trips Available',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for backhaul opportunities',
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
                await provider.fetchOpportunities(truckId);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: opportunities.length,
              itemBuilder: (context, index) {
                return _buildBackhaulCard(opportunities[index], provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackhaulCard(BackhaulModel backhaul, BackhaulProvider provider) {
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
                child: const Icon(Icons.u_turn_left, color: AppTheme.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Return Trip Opportunity',
                      style: AppTheme.headingSmall,
                    ),
                    Text(
                      backhaul.shipperName,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Route
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(width: 2, height: 24, color: AppTheme.surfaceLight),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
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
                      backhaul.shipperLocation,
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      backhaul.destinationHubName ?? 'Destination Hub',
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Packages',
                        '${backhaul.packageCount}',
                        Icons.inventory_2_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Weight',
                        '${backhaul.totalWeight.toStringAsFixed(0)} kg',
                        Icons.scale_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Distance',
                        '${backhaul.distanceKm.toStringAsFixed(1)} km',
                        Icons.route,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.eco, size: 16, color: AppTheme.success),
                      const SizedBox(width: 6),
                      Text(
                        'Carbon Saved: ${backhaul.carbonSavedKg.toStringAsFixed(1)} kg CO₂',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contact
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(backhaul.shipperPhone, style: AppTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Call shipper
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    final truckId = authProvider.user?.trucks.firstOrNull?.id;
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
                      backhaul.id,
                      truckId,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backhaul accepted!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
