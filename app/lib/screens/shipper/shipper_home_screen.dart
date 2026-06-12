import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shipment_provider.dart';
import '../../widgets/shipment_card.dart';
import '../../widgets/loading_indicator.dart';
import 'create_shipment_screen.dart';
import 'shipment_details_screen.dart';
import 'shipper_profile_screen.dart';

/// Shipper Home Screen with bottom navigation
class ShipperHomeScreen extends StatefulWidget {
  const ShipperHomeScreen({super.key});

  @override
  State<ShipperHomeScreen> createState() => _ShipperHomeScreenState();
}

class _ShipperHomeScreenState extends State<ShipperHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _ShipperHomeContent(),
    const _MyShipmentsTab(),
    const ShipperProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentProvider>().fetchShipments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: _currentIndex < 2
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateShipmentScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Shipment'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Shipments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Home tab content
class _ShipperHomeContent extends StatelessWidget {
  const _ShipperHomeContent();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shipmentProvider = context.watch<ShipmentProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello,',
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
            Text(user?.name ?? 'Shipper', style: AppTheme.headingSmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Notifications
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary,
              child: Text(
                user?.initials ?? 'S',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => shipmentProvider.fetchShipments(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats
              _buildQuickStats(shipmentProvider),
              const SizedBox(height: 24),

              // Quick Actions
              Text('Quick Actions', style: AppTheme.headingSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      Icons.add_box_outlined,
                      'New Shipment',
                      'Create a shipment',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateShipmentScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      Icons.history,
                      'Track',
                      'Track shipments',
                      () {
                        // Navigate to shipments tab
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Shipments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Shipments', style: AppTheme.headingSmall),
                  TextButton(
                    onPressed: () {
                      // Navigate to shipments tab
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildActiveShipments(context, shipmentProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(ShipmentProvider provider) {
    final activeCount = provider.inTransitShipments.length;
    final pendingCount = provider.pendingShipments.length;
    final completedCount = provider.completedShipments.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shipment Overview',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Icon(Icons.analytics, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Active', '$activeCount', Colors.black),
              ),
              Container(width: 1, height: 40, color: Colors.black26),
              Expanded(
                child: _buildStatItem('Pending', '$pendingCount', Colors.black),
              ),
              Container(width: 1, height: 40, color: Colors.black26),
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  '$completedCount',
                  Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTheme.labelLarge),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTheme.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveShipments(
    BuildContext context,
    ShipmentProvider provider,
  ) {
    if (provider.isLoading && provider.shipments.isEmpty) {
      return const ShimmerList(itemCount: 2, itemHeight: 160);
    }

    final activeShipments = [
      ...provider.inTransitShipments,
      ...provider.pendingShipments,
    ];

    if (activeShipments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text('No active shipments', style: AppTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Create a new shipment to get started',
              style: AppTheme.caption,
            ),
          ],
        ),
      );
    }

    return Column(
      children: activeShipments.take(3).map((shipment) {
        return ShipmentCard(
          shipment: shipment,
          onTap: () {
            provider.selectShipment(shipment);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShipmentDetailsScreen(shipment: shipment),
              ),
            );
          },
          onCancel: shipment.canCancel
              ? () {
                  provider.cancelShipment(shipment.id);
                }
              : null,
        );
      }).toList(),
    );
  }
}

/// My Shipments tab
class _MyShipmentsTab extends StatelessWidget {
  const _MyShipmentsTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Shipments'),
          bottom: TabBar(
            tabs: [
              Consumer<ShipmentProvider>(
                builder: (context, provider, _) =>
                    Tab(text: 'Active (${provider.inTransitShipments.length})'),
              ),
              Consumer<ShipmentProvider>(
                builder: (context, provider, _) =>
                    Tab(text: 'Pending (${provider.pendingShipments.length})'),
              ),
              const Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ShipmentListView(
              filter: (s) => s.where((x) => x.isInTransit).toList(),
              emptyMessage: 'No active shipments',
            ),
            _ShipmentListView(
              filter: (s) => s.where((x) => x.isPending).toList(),
              emptyMessage: 'No pending shipments',
            ),
            _ShipmentListView(
              filter: (s) => s.where((x) => x.isCompleted).toList(),
              emptyMessage: 'No completed shipments',
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipmentListView extends StatelessWidget {
  final List<dynamic> Function(List<dynamic>) filter;
  final String emptyMessage;

  const _ShipmentListView({required this.filter, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShipmentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.shipments.isEmpty) {
          return const ShimmerList(itemCount: 5, itemHeight: 160);
        }

        final filtered = filter(provider.shipments);

        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.inventory_2_outlined,
            title: emptyMessage,
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchShipments(),
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final shipment = filtered[index];
              return ShipmentCard(
                shipment: shipment,
                onTap: () {
                  provider.selectShipment(shipment);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShipmentDetailsScreen(shipment: shipment),
                    ),
                  );
                },
                onCancel: shipment.canCancel
                    ? () => provider.cancelShipment(shipment.id)
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}
