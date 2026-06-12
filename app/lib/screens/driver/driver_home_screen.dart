import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/delivery_card.dart';
import '../../widgets/loading_indicator.dart';
import 'delivery_list_screen.dart';
import 'delivery_details_screen.dart';
import 'earnings_screen.dart';
import 'driver_profile_screen.dart';
import 'return_loads_screen.dart';
import 'synergy_opportunities_screen.dart';
import '../audit/box_audit_entry_screen.dart';

/// Driver Home Screen with bottom navigation
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DriverHomeContent(),
    const DeliveryListScreen(),
    const EarningsScreen(),
    const DriverProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
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
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
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
class _DriverHomeContent extends StatelessWidget {
  const _DriverHomeContent();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final deliveryProvider = context.watch<DeliveryProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
            Text(user?.name ?? 'Driver', style: AppTheme.headingSmall),
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
                user?.initials ?? 'D',
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
        onRefresh: () => deliveryProvider.refreshAll(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earnings Card
              _buildEarningsCard(context, user),
              const SizedBox(height: 20),

              // Quick Actions
              _buildQuickActions(context, deliveryProvider),
              const SizedBox(height: 24),

              // Active Deliveries Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Deliveries', style: AppTheme.headingSmall),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeliveryListScreen(),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Deliveries list
              _buildDeliveriesList(context, deliveryProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, DeliveryProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.swap_horiz,
                title: 'Return Loads',
                subtitle: '${provider.returnLoadsCount} available',
                color: AppTheme.info,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReturnLoadsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.handshake_outlined,
                title: 'Synergy',
                subtitle: 'Hub Transfers',
                color: AppTheme.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SynergyOpportunitiesScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _QuickActionCard(
          icon: Icons.fact_check_outlined,
          title: 'Box Audit',
          subtitle: '2-view visual check',
          color: AppTheme.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BoxAuditEntryScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEarningsCard(BuildContext context, user) {
    final weeklySummary = context.watch<DeliveryProvider>().weeklySummary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'This Week',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, size: 14, color: Colors.black87),
                    SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(weeklySummary?.earnings ?? user?.weeklyEarnings ?? 0)}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEarningsInfoItem(
                  'Total Earnings',
                  '₹${NumberFormat('#,##,###').format(user?.totalEarnings ?? 0)}',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.black26),
              Expanded(
                child: _buildEarningsInfoItem(
                  'Deliveries',
                  '${user?.deliveriesCount ?? 0}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDeliveriesList(BuildContext context, DeliveryProvider provider) {
    if (provider.isLoading && provider.deliveries.isEmpty) {
      return const ShimmerList(itemCount: 3, itemHeight: 140);
    }

    final activeDeliveries = provider.activeDeliveries;
    final pendingDeliveries = provider.pendingDeliveries;
    final allActive = [...activeDeliveries, ...pendingDeliveries];

    if (allActive.isEmpty) {
      return const EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No Active Deliveries',
        subtitle: 'You will see new deliveries here when assigned',
      );
    }

    return Column(
      children: allActive.take(3).map((delivery) {
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
      }).toList(),
    );
  }
}

/// Quick action card widget for home screen navigation
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(title, style: AppTheme.labelLarge),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
