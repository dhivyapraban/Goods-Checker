import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class EWayBillsScreen extends StatelessWidget {
  const EWayBillsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual API call
    final bills = [
      {
        'id': 'EWB001',
        'billNo': '123456789012',
        'validFrom': '2026-02-01',
        'validUntil': '2026-02-03',
        'status': 'ACTIVE',
        'consignor': 'ABC Industries',
        'consignee': 'XYZ Traders',
        'distance': '450 km',
      },
      {
        'id': 'EWB002',
        'billNo': '987654321098',
        'validFrom': '2026-01-30',
        'validUntil': '2026-02-01',
        'status': 'EXPIRING_SOON',
        'consignor': 'DEF Manufacturers',
        'consignee': 'PQR Distributors',
        'distance': '320 km',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('E-Way Bills')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          return _buildBillCard(context, bill);
        },
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, Map<String, dynamic> bill) {
    final isExpiring = bill['status'] == 'EXPIRING_SOON';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isExpiring
            ? Border.all(color: AppTheme.warning, width: 2)
            : null,
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
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description, color: AppTheme.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('E-Way Bill', style: AppTheme.headingSmall),
                    Text(
                      bill['billNo'],
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isExpiring
                      ? AppTheme.warning.withOpacity(0.1)
                      : AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpiring ? 'Expiring Soon' : 'Active',
                  style: AppTheme.bodySmall.copyWith(
                    color: isExpiring ? AppTheme.warning : AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('From', bill['consignor']),
          const SizedBox(height: 8),
          _buildInfoRow('To', bill['consignee']),
          const SizedBox(height: 8),
          _buildInfoRow('Distance', bill['distance']),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Valid: ${bill['validFrom']} to ${bill['validUntil']}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: View bill details
            },
            icon: const Icon(Icons.visibility),
            label: const Text('View Details'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        Expanded(child: Text(value, style: AppTheme.bodyMedium)),
      ],
    );
  }
}
