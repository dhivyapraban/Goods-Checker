import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegistrationApprovalScreen extends StatelessWidget {
  const RegistrationApprovalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final status = user?.registrationStatus ?? 'PENDING';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIcon(status),
              const SizedBox(height: 24),
              Text(
                _getTitle(status),
                style: AppTheme.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _getMessage(status),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (status == 'PENDING') ...[
                _buildInfoCard(
                  'What happens next?',
                  'Our team is reviewing your registration. This usually takes 24-48 hours.',
                  Icons.schedule,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  'Documents Submitted',
                  'License, Vehicle RC, Insurance',
                  Icons.check_circle_outline,
                ),
              ],
              if (status == 'REJECTED') ...[
                _buildInfoCard(
                  'Reason for Rejection',
                  'Invalid vehicle documents. Please re-submit with correct information.',
                  Icons.error_outline,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to re-registration
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-submit Documents'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
              if (status == 'SUSPENDED') ...[
                _buildInfoCard(
                  'Account Suspended',
                  'Please contact support for more information.',
                  Icons.block,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Contact support
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contact Support'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'PENDING':
        icon = Icons.hourglass_empty;
        color = AppTheme.warning;
        break;
      case 'REJECTED':
        icon = Icons.cancel;
        color = AppTheme.error;
        break;
      case 'SUSPENDED':
        icon = Icons.block;
        color = AppTheme.error;
        break;
      default:
        icon = Icons.check_circle;
        color = AppTheme.success;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 56, color: color),
    );
  }

  String _getTitle(String status) {
    switch (status) {
      case 'PENDING':
        return 'Registration Pending';
      case 'REJECTED':
        return 'Registration Rejected';
      case 'SUSPENDED':
        return 'Account Suspended';
      default:
        return 'Registration Approved';
    }
  }

  String _getMessage(String status) {
    switch (status) {
      case 'PENDING':
        return 'Your registration is under review. We\'ll notify you once it\'s approved.';
      case 'REJECTED':
        return 'Your registration was rejected. Please review the reason below and re-submit.';
      case 'SUSPENDED':
        return 'Your account has been suspended. Contact support for assistance.';
      default:
        return 'Your registration has been approved. You can now start accepting deliveries.';
    }
  }

  Widget _buildInfoCard(String title, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.headingSmall),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
