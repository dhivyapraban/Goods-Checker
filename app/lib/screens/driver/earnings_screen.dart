import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/loading_indicator.dart';

/// Earnings screen for driver
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().fetchTransactions();
      context.read<DeliveryProvider>().fetchWeeklySummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<DeliveryProvider>();
    final summary = provider.weeklySummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchTransactions();
          await provider.fetchWeeklySummary();
        },
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Today',
                      '₹${NumberFormat('#,##,###').format(summary?.dailyBreakdown[DateFormat('yyyy-MM-dd').format(DateTime.now())] ?? 0)}',
                      Icons.today,
                      AppTheme.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'This Week',
                      '₹${NumberFormat('#,##,###').format(summary?.earnings ?? user?.weeklyEarnings ?? 0)}',
                      Icons.date_range,
                      AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'This Month',
                      '₹${NumberFormat('#,##,###').format((summary?.earnings ?? 0) * 4)}',
                      Icons.calendar_month,
                      AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total',
                      '₹${NumberFormat('#,##,###').format(summary?.totalEarnings ?? user?.totalEarnings ?? 0)}',
                      Icons.account_balance_wallet,
                      AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Chart Placeholder
              _buildWeeklyChart(summary?.dailyBreakdown ?? {}),
              const SizedBox(height: 24),

              // Transaction History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transaction History', style: AppTheme.headingSmall),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Filter
                    },
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Filter'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Transactions list
              if (provider.isLoading && provider.transactions.isEmpty)
                const ShimmerList(itemCount: 5, itemHeight: 80)
              else if (provider.transactions.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Transactions',
                  subtitle: 'Your earnings will appear here',
                )
              else
                ...provider.transactions.map(_buildTransactionItem),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppTheme.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.headingSmall.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(Map<String, double> dailyBreakdown) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateFormat('yyyy-MM-dd').format(date);
    });

    final maxValue = dailyBreakdown.values.isEmpty
        ? 1.0
        : dailyBreakdown.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Overview', style: AppTheme.labelLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final value = dailyBreakdown[day] ?? 0;
                final height = maxValue > 0 ? (value / maxValue) * 80 : 0;
                final dayLabel = DateFormat('E').format(DateTime.parse(day));

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: height.toDouble() + 8,
                      decoration: BoxDecoration(
                        color: day == DateFormat('yyyy-MM-dd').format(now)
                            ? AppTheme.primary
                            : AppTheme.primary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayLabel,
                      style: AppTheme.caption.copyWith(
                        color: day == DateFormat('yyyy-MM-dd').format(now)
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(transaction) {
    final isPositive = transaction.isPositive;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPositive ? AppTheme.success : AppTheme.error)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? AppTheme.success : AppTheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.typeLabel, style: AppTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  transaction.route ?? transaction.description,
                  style: AppTheme.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}₹${NumberFormat('#,##,###').format(transaction.amount.abs())}',
                style: AppTheme.labelLarge.copyWith(
                  color: isPositive ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM dd').format(transaction.createdAt),
                style: AppTheme.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
