import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/shipment_model.dart';
import '../../widgets/qr_code_widget.dart';
import 'shipment_tracking_screen.dart';

/// Screen for shipper to display QR code at pickup location
/// Driver scans this QR to confirm pickup
class ShipperQrScreen extends StatefulWidget {
  final ShipmentModel shipment;

  const ShipperQrScreen({super.key, required this.shipment});

  @override
  State<ShipperQrScreen> createState() => _ShipperQrScreenState();
}

class _ShipperQrScreenState extends State<ShipperQrScreen> {
  String? _qrData;
  bool _isLoading = true;
  String? _error;
  bool _isScanned = false;

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
      // The backend would create a secure token for verification
      final qrPayload = {
        'type': 'SHIPPER_PICKUP',
        'shipmentId': widget.shipment.id,
        'shipperId': widget.shipment.shipperId,
        'pickupLocation': widget.shipment.pickupLocation,
        'dropLocation': widget.shipment.dropLocation,
        'cargoType': widget.shipment.cargoType,
        'cargoWeight': widget.shipment.cargoWeight,
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

  /// Called when driver scans the QR successfully (simulated for demo)
  void _onScanSuccess() {
    setState(() {
      _isScanned = true;
    });

    // Navigate to tracking after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ShipmentTrackingScreen(shipment: widget.shipment),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pickup QR Code'),
        backgroundColor: AppTheme.background,
        actions: [
          if (!_isScanned)
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
          child: _isScanned ? _buildSuccessView() : _buildQrView(),
        ),
      ),
    );
  }

  Widget _buildQrView() {
    return Column(
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
              const Icon(Icons.qr_code, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Show this QR code to the driver when they arrive for pickup',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.primary),
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
          title: 'Pickup QR Code',
          subtitle: 'Shipment #${widget.shipment.id.substring(0, 8)}',
        ),

        const SizedBox(height: 32),

        // Shipment Summary Card
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
                'Shipment Details',
                style: AppTheme.labelLarge.copyWith(color: AppTheme.primary),
              ),
              const SizedBox(height: 16),

              // Pickup Location
              _buildDetailRow(
                'Pickup',
                widget.shipment.pickupLocation ?? 'Not specified',
                Icons.location_on_outlined,
                AppTheme.success,
              ),
              const SizedBox(height: 12),

              // Drop Location
              _buildDetailRow(
                'Drop',
                widget.shipment.dropLocation ?? 'Not specified',
                Icons.flag_outlined,
                AppTheme.error,
              ),
              const SizedBox(height: 12),

              // Cargo
              if (widget.shipment.cargoType != null) ...[
                _buildDetailRow(
                  'Cargo',
                  '${widget.shipment.cargoType} • ${widget.shipment.cargoWeight?.toStringAsFixed(1) ?? '0'} kg',
                  Icons.inventory_2_outlined,
                  AppTheme.info,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Waiting indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                'Waiting for driver to scan...',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.info),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Driver Info (if assigned)
        if (widget.shipment.delivery?.driver != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shipment.delivery!.driver!.name,
                        style: AppTheme.labelLarge,
                      ),
                      Text('Assigned Driver', style: AppTheme.caption),
                    ],
                  ),
                ),
                if (widget.shipment.delivery!.driver!.phone != null)
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppTheme.success),
                    onPressed: () {
                      // Launch phone dialer
                    },
                  ),
              ],
            ),
          ),
        ],
        // Demo: Simulate scan button (for testing)
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _onScanSuccess,
          icon: const Icon(Icons.bug_report, size: 16),
          label: const Text('Simulate Scan (Demo)'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const SizedBox(height: 48),

        // Success Icon
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
          'Goods Picked Up!',
          style: AppTheme.headingLarge.copyWith(color: AppTheme.success),
        ),

        const SizedBox(height: 12),

        Text(
          'E-way bill has been generated.\nYou can now track your shipment.',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        const CircularProgressIndicator(color: AppTheme.primary),

        const SizedBox(height: 16),

        Text('Redirecting to tracking...', style: AppTheme.bodySmall),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
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
