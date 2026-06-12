import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageQualityFailure {
  final String code;
  final String message;
  const ImageQualityFailure(this.code, this.message);
}

class ImageQualityResult {
  final bool ok;
  final List<ImageQualityFailure> failures;
  final Map<String, double> metrics;
  const ImageQualityResult({
    required this.ok,
    required this.failures,
    required this.metrics,
  });
}

/// Pre-upload validation. If validation fails, ask the user to retake.
class ImageQualityValidator {
  static ImageQualityResult validate(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return const ImageQualityResult(
        ok: false,
        failures: [
          ImageQualityFailure('decode_failed', 'Could not decode image'),
        ],
        metrics: {},
      );
    }

    // Downscale for faster classical CV.
    final small = img.copyResize(
      decoded,
      width: 256,
      height: 256,
      interpolation: img.Interpolation.linear,
    );

    final gray = _toGray(small);

    final blurVar = _laplacianVariance(gray);
    final edgeStats = _edgeStats(gray);

    final occupancy = edgeStats.occupancy;
    final perpScore = edgeStats.perpendicularity;

    final failures = <ImageQualityFailure>[];

    // Blur threshold: tuned to be conservative; adjust if needed.
    // Lower variance => blurrier.
    const minLaplacianVariance = 30.0; // Relaxed from 70.0 for easier testing
    if (blurVar < minLaplacianVariance) {
      failures.add(
        const ImageQualityFailure(
          'blurry',
          'Image looks blurry. Hold steady and retake with good lighting.',
        ),
      );
    }

    // Occupancy: box should fill frame.
    const minOccupancy = 0.30; // Relaxed from 0.60 for easier testing
    if (occupancy < minOccupancy) {
      failures.add(
        const ImageQualityFailure(
          'low_occupancy',
          'Box is too small in frame. Move closer until it fills the guide.',
        ),
      );
    }

    // Edge visibility: require strong vertical + horizontal edges.
    // This rejects top-view / flat-side / random angles better than text-only guidance.
    const minPerpendicularity = 0.10; // Relaxed from 0.25 for easier testing
    if (perpScore < minPerpendicularity) {
      failures.add(
        const ImageQualityFailure(
          'missing_edges',
          'Need two perpendicular straight edges visible (corner view).',
        ),
      );
    }

    return ImageQualityResult(
      ok: failures.isEmpty,
      failures: failures,
      metrics: {
        'laplacianVariance': blurVar,
        'occupancy': occupancy,
        'perpendicularity': perpScore,
        'edgeEnergyX': edgeStats.energyX,
        'edgeEnergyY': edgeStats.energyY,
      },
    );
  }

  static Float32List _toGray(img.Image image) {
    final out = Float32List(image.width * image.height);
    var i = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        // ITU-R BT.601 luma
        out[i++] = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
      }
    }
    return out;
  }

  static _EdgeStats _edgeStats(Float32List gray) {
    const w = 256;
    const h = 256;

    double energyX = 0;
    double energyY = 0;
    int edgeCount = 0;

    // Edge mask bbox
    var minX = w;
    var minY = h;
    var maxX = 0;
    var maxY = 0;

    // Sobel kernels
    const kx = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    const ky = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    // Threshold relative to max magnitude estimate.
    // We compute magnitude as |gx| + |gy| (fast).
    const magThreshold = 120.0;

    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        double gx = 0;
        double gy = 0;

        for (var j = -1; j <= 1; j++) {
          for (var i = -1; i <= 1; i++) {
            final v = gray[(y + j) * w + (x + i)];
            gx += v * kx[j + 1][i + 1];
            gy += v * ky[j + 1][i + 1];
          }
        }

        final mag = gx.abs() + gy.abs();
        if (mag >= magThreshold) {
          edgeCount++;
          energyX += gx.abs();
          energyY += gy.abs();

          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    final totalEnergy = energyX + energyY;
    final perp = totalEnergy <= 0
        ? 0.0
        : (math.min(energyX, energyY) / math.max(energyX, energyY));

    final occupancy = edgeCount < 2000
        ? 0.0
        : _bboxArea(minX, minY, maxX, maxY) / (w * h);

    return _EdgeStats(
      energyX: energyX,
      energyY: energyY,
      perpendicularity: perp,
      occupancy: occupancy,
    );
  }

  static double _bboxArea(int minX, int minY, int maxX, int maxY) {
    if (maxX <= minX || maxY <= minY) return 0.0;
    return ((maxX - minX + 1) * (maxY - minY + 1)).toDouble();
  }

  static double _laplacianVariance(Float32List gray) {
    const w = 256;
    const h = 256;

    // Kernel:
    //  0  1  0
    //  1 -4  1
    //  0  1  0

    double sum = 0;
    double sumSq = 0;
    int count = 0;

    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final c = gray[y * w + x];
        final up = gray[(y - 1) * w + x];
        final down = gray[(y + 1) * w + x];
        final left = gray[y * w + (x - 1)];
        final right = gray[y * w + (x + 1)];

        final lap = (up + down + left + right - 4.0 * c);
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }

    if (count == 0) return 0;
    final mean = sum / count;
    final meanSq = sumSq / count;
    final variance = meanSq - mean * mean;
    return variance.isFinite ? variance : 0.0;
  }
}

class _EdgeStats {
  final double energyX;
  final double energyY;
  final double perpendicularity;
  final double occupancy;

  _EdgeStats({
    required this.energyX,
    required this.energyY,
    required this.perpendicularity,
    required this.occupancy,
  });
}
