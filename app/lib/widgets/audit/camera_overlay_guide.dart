import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class CameraOverlayGuide extends StatelessWidget {
  final String title;
  final String subtitle;

  const CameraOverlayGuide({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Top label
          Positioned(
            left: 16,
            right: 16,
            top: 48,
            child: _Banner(title: title, subtitle: subtitle),
          ),

          // Center framing box
          Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: CustomPaint(painter: _GuidePainter()),
            ),
          ),

          // Bottom instruction
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Capture a CORNER at ~45°. Avoid top-view and flat side view.\n'
                'Fill the guide (≥60%), keep two perpendicular edges visible, and hold steady.',
                style: AppTheme.bodySmall.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Banner({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.headingSmall.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTheme.bodySmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Dim outside guide
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.35);
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(-10000, -10000, 20000, 20000));
    final guideRect = RRect.fromRectAndRadius(
      rect.deflate(size.width * 0.10),
      const Radius.circular(16),
    );
    final guidePath = Path()..addRRect(guideRect);

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawPath(path, overlayPaint);
    canvas.drawPath(guidePath, clearPaint);
    canvas.restore();

    // Guide border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(guideRect, borderPaint);

    // Corner markers
    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    const cornerLen = 24.0;
    final r = guideRect.outerRect;

    // TL
    canvas.drawLine(
      Offset(r.left, r.top),
      Offset(r.left + cornerLen, r.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(r.left, r.top),
      Offset(r.left, r.top + cornerLen),
      cornerPaint,
    );
    // TR
    canvas.drawLine(
      Offset(r.right, r.top),
      Offset(r.right - cornerLen, r.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(r.right, r.top),
      Offset(r.right, r.top + cornerLen),
      cornerPaint,
    );
    // BL
    canvas.drawLine(
      Offset(r.left, r.bottom),
      Offset(r.left + cornerLen, r.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(r.left, r.bottom),
      Offset(r.left, r.bottom - cornerLen),
      cornerPaint,
    );
    // BR
    canvas.drawLine(
      Offset(r.right, r.bottom),
      Offset(r.right - cornerLen, r.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(r.right, r.bottom),
      Offset(r.right, r.bottom - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
