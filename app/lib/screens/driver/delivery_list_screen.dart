import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/delivery_card.dart';
import '../../widgets/loading_indicator.dart';
import 'delivery_details_screen.dart';

/// Delivery list screen with tabs
class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deliveries'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Consumer<DeliveryProvider>(
              builder: (context, provider, _) =>
                  Tab(text: 'Active (${provider.activeDeliveries.length})'),
            ),
            Consumer<DeliveryProvider>(
              builder: (context, provider, _) =>
                  Tab(text: 'Pending (${provider.pendingDeliveries.length})'),
            ),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DeliveryTab(
            filter: (deliveries) =>
                deliveries.where((d) => d.isActive).toList(),
            emptyMessage: 'No active deliveries',
            emptyIcon: Icons.local_shipping_outlined,
          ),
          _DeliveryTab(
            filter: (deliveries) =>
                deliveries.where((d) => d.isPending).toList(),
            emptyMessage: 'No pending deliveries',
            emptyIcon: Icons.pending_outlined,
          ),
          _DeliveryTab(
            filter: (deliveries) =>
                deliveries.where((d) => d.isCompleted).toList(),
            emptyMessage: 'No completed deliveries',
            emptyIcon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}

class _DeliveryTab extends StatelessWidget {
  final List<dynamic> Function(List<dynamic>) filter;
  final String emptyMessage;
  final IconData emptyIcon;

  const _DeliveryTab({
    required this.filter,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.deliveries.isEmpty) {
          return const ShimmerList(itemCount: 5, itemHeight: 140);
        }

        final filtered = filter(provider.deliveries);

        if (filtered.isEmpty) {
          return EmptyState(icon: emptyIcon, title: emptyMessage);
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchDeliveries(),
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final delivery = filtered[index];
              return DeliveryCard(
                delivery: delivery,
                onTap: () {
                  provider.selectDelivery(delivery);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeliveryDetailsScreen(delivery: delivery),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
