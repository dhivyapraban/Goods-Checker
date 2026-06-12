import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/qr_code_widget.dart';

/// Screen for driver to display QR code for hub transfer
/// Truck A generates this QR for Truck B to scan
class QrDisplayScreen extends StatefulWidget {
  final String opportunityId;
  final String? deliveryId;
  final String? origin;
  final String? destination;
  final String? cargoType;
  final double? cargoWeight;

  const QrDisplayScreen({
    super.key,
    required this.opportunityId,
    this.deliveryId,
    this.origin,
    this.destination,
    this.cargoType,
    this.cargoWeight,
  });

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  String? _qrData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateQrCode();
  }

  Future<void> _generateQrCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Generate QR data - this would normally come from the backend
      // For now, we create a JSON structure with transfer info
      final qrPayload = {
        'type': 'SYNERGY_TRANSFER',
        'opportunityId': widget.opportunityId,
        'deliveryId': widget.deliveryId,
        'origin': widget.origin,
        'destination': widget.destination,
        'cargoType': widget.cargoType,
        'cargoWeight': widget.cargoWeight,
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _qrData = jsonEncode(qrPayload);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate QR code';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Transfer QR Code'),
        backgroundColor: AppTheme.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateQrCode,
            tooltip: 'Regenerate QR',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Show this QR code to the receiving driver to complete the transfer',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // QR Code
              QrCodeWithLoading(
                data: _qrData,
                isLoading: _isLoading,
                error: _error,
                size: 280,
                title: 'Transfer QR',
                subtitle: 'Scan to receive cargo',
              ),

              const SizedBox(height: 32),

              // Transfer Details Card
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
                      'Transfer Details',
                      style: AppTheme.labelLarge.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Origin
                    _buildDetailRow(
                      'From',
                      widget.origin ?? 'Not specified',
                      Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),

                    // Destination
                    _buildDetailRow(
                      'To',
                      widget.destination ?? 'Not specified',
                      Icons.flag_outlined,
                    ),
                    const SizedBox(height: 12),

                    // Cargo Type
                    if (widget.cargoType != null) ...[
                      _buildDetailRow(
                        'Cargo',
                        widget.cargoType!,
                        Icons.inventory_2_outlined,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Weight
                    if (widget.cargoWeight != null) ...[
                      _buildDetailRow(
                        'Weight',
                        '${widget.cargoWeight!.toStringAsFixed(1)} kg',
                        Icons.scale_outlined,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Waiting indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for scan...',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.info),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.caption),
              Text(value, style: AppTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
