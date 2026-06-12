import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/app_theme.dart';

/// Reusable QR Code display widget
class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final String? title;
  final String? subtitle;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final bool showBorder;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 250,
    this.title,
    this.subtitle,
    this.foregroundColor,
    this.backgroundColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        if (title != null) ...[
          Text(
            title!,
            style: AppTheme.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],

        // Subtitle
        if (subtitle != null) ...[
          Text(
            subtitle!,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],

        // QR Code Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: showBorder
                ? Border.all(color: AppTheme.primary, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            backgroundColor: backgroundColor ?? Colors.white,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: foregroundColor ?? Colors.black,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: foregroundColor ?? Colors.black,
            ),
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),
      ],
    );
  }
}

/// QR Code widget with loading state
class QrCodeWithLoading extends StatelessWidget {
  final String? data;
  final bool isLoading;
  final String? error;
  final double size;
  final String? title;
  final String? subtitle;

  const QrCodeWithLoading({
    super.key,
    this.data,
    this.isLoading = false,
    this.error,
    this.size = 250,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTheme.headingMedium),
            const SizedBox(height: 24),
          ],
          Container(
            width: size + 32,
            height: size + 32,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary, width: 3),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
        ],
      );
    }

    if (error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTheme.headingMedium),
            const SizedBox(height: 24),
          ],
          Container(
            width: size + 32,
            height: size + 32,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.error, width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (data == null || data!.isEmpty) {
      return const SizedBox.shrink();
    }

    return QrCodeWidget(
      data: data!,
      size: size,
      title: title,
      subtitle: subtitle,
    );
  }
}
