import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';

/// Payment screen for Razorpay checkout
class PaymentScreen extends StatefulWidget {
  final String shipmentId;
  final double amount;
  final bool isInitialPayment;
  final String? description;

  const PaymentScreen({
    super.key,
    required this.shipmentId,
    required this.amount,
    this.isInitialPayment = true,
    this.description,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialize payment service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().initPaymentService(context);
    });
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isProcessing = true;
    });

    final paymentProvider = context.read<PaymentProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    // Create payment order
    final success = await paymentProvider.createPaymentOrder(
      amount: widget.amount,
      shipmentId: widget.shipmentId,
      paymentType: widget.isInitialPayment ? 'INITIAL' : 'FINAL',
    );

    if (success && mounted) {
      // Open Razorpay checkout
      // Note: email is derived from phone since UserModel doesn't store email
      final email = user?.phone != null
          ? '${user!.phone}@ecologiq.app'
          : 'customer@ecologiq.app';

      paymentProvider.openCheckout(
        customerName: user?.name ?? 'Customer',
        customerPhone: user?.phone ?? '',
        customerEmail: email,
        shipmentId: widget.shipmentId,
        isInitialPayment: widget.isInitialPayment,
      );
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.isInitialPayment ? 'Initial Payment' : 'Final Payment',
        ),
        backgroundColor: AppTheme.background,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, _) {
          final isLoading = paymentProvider.isLoading || _isProcessing;
          final hasPayment = paymentProvider.currentPayment != null;

          if (hasPayment && paymentProvider.currentPayment!.isSuccess) {
            return _buildSuccessView(paymentProvider);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  widget.isInitialPayment
                      ? 'Confirm Initial Payment'
                      : 'Complete Final Payment',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description ??
                      (widget.isInitialPayment
                          ? 'Pay to confirm your shipment booking'
                          : 'Pay the remaining amount after delivery'),
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Amount Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.8),
                        AppTheme.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Amount to Pay',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Shipment #${widget.shipmentId.substring(0, 8)}',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Payment Breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Details',
                        style: AppTheme.labelLarge.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBreakdownRow(
                        'Subtotal',
                        '₹${(widget.amount * 0.82).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildBreakdownRow(
                        'GST (18%)',
                        '₹${(widget.amount * 0.18).toStringAsFixed(2)}',
                      ),
                      const Divider(height: 24),
                      _buildBreakdownRow(
                        'Total',
                        '₹${widget.amount.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Methods Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accepted Payment Methods',
                        style: AppTheme.labelLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildPaymentMethodIcon('UPI'),
                          const SizedBox(width: 8),
                          _buildPaymentMethodIcon('Cards'),
                          const SizedBox(width: 8),
                          _buildPaymentMethodIcon('Netbanking'),
                          const SizedBox(width: 8),
                          _buildPaymentMethodIcon('Wallets'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Error message
                if (paymentProvider.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            paymentProvider.error!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _initiatePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Pay ₹${widget.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Security Note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_user,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text('Secured by Razorpay', style: AppTheme.caption),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessView(PaymentProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppTheme.success,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Successful!',
            style: AppTheme.headingLarge.copyWith(color: AppTheme.success),
          ),
          const SizedBox(height: 12),
          Text(
            '₹${widget.amount.toStringAsFixed(2)}',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Transaction ID: ${provider.currentPayment?.paymentId ?? 'N/A'}',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              provider.clearPayment();
              Navigator.pop(context, true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTheme.labelLarge
              : AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: isTotal
              ? AppTheme.labelLarge.copyWith(color: AppTheme.primary)
              : AppTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodIcon(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
      ),
    );
  }
}
