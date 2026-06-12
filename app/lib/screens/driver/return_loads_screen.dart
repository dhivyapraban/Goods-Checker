import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/loading_indicator.dart';
import 'delivery_details_screen.dart';

/// Return Loads screen for driver to see available and assigned return loads
class ReturnLoadsScreen extends StatefulWidget {
  const ReturnLoadsScreen({super.key});

  @override
  State<ReturnLoadsScreen> createState() => _ReturnLoadsScreenState();
}

class _ReturnLoadsScreenState extends State<ReturnLoadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReturnLoads();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReturnLoads() async {
    await context.read<DeliveryProvider>().loadReturnLoads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Return Loads'),
        backgroundColor: AppTheme.background,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Assigned'),
            Tab(text: 'Available'),
          ],
        ),
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: LoadingIndicator(message: 'Loading return loads...'),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Assigned Tab
              _ReturnLoadsList(
                loads: provider.assignedReturnLoads,
                emptyMessage: 'No assigned return loads',
                emptyIcon: Icons.local_shipping_outlined,
                onRefresh: _loadReturnLoads,
                isAssigned: true,
              ),

              // Available Tab
              _ReturnLoadsList(
                loads: provider.availableReturnLoads,
                emptyMessage: 'No available return loads nearby',
                emptyIcon: Icons.search_off,
                onRefresh: _loadReturnLoads,
                isAssigned: false,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReturnLoadsList extends StatelessWidget {
  final List<DeliveryModel> loads;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;
  final bool isAssigned;

  const _ReturnLoadsList({
    required this.loads,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
    required this.isAssigned,
  });

  @override
  Widget build(BuildContext context) {
    if (loads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loads.length,
        itemBuilder: (context, index) {
          return _ReturnLoadCard(
            delivery: loads[index],
            isAssigned: isAssigned,
          );
        },
      ),
    );
  }
}

class _ReturnLoadCard extends StatelessWidget {
  final DeliveryModel delivery;
  final bool isAssigned;

  const _ReturnLoadCard({required this.delivery, required this.isAssigned});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isAssigned
            ? BorderSide(color: AppTheme.primary.withOpacity(0.3))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeliveryDetailsScreen(delivery: delivery),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swap_horiz,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Return Load',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${delivery.totalEarnings.toStringAsFixed(0)}',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Route
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      delivery.pickupLocation,
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: 2,
                  height: 16,
                  color: AppTheme.surfaceLight,
                ),
              ),

              Row(
                children: [
                  const Icon(Icons.flag, size: 18, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      delivery.dropLocation,
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cargo and Distance
              Row(
                children: [
                  _buildInfoChip(
                    Icons.inventory_2_outlined,
                    delivery.cargoType,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.scale_outlined,
                    '${delivery.cargoWeight.toStringAsFixed(0)} kg',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.route,
                    '${delivery.distanceKm.toStringAsFixed(0)} km',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action button
              if (!isAssigned)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final provider = context.read<DeliveryProvider>();
                      final success = await provider.acceptReturnLoad(
                        delivery.id,
                      );
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Return load accepted!'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    },
                    child: const Text('Accept Return Load'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DeliveryDetailsScreen(delivery: delivery),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Navigate to Pickup'),
                  ),
                ),
            ],
          ),
        ),
      ),
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
            style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
