import 'dart:math';
import 'dart:ui';

import 'cv_config.dart';

class AnomalyRegion {
  final double normalizedX;
  final double normalizedY;
  final double magnitude;

  const AnomalyRegion({
    required this.normalizedX,
    required this.normalizedY,
    required this.magnitude,
  });
}

// Detects local deviations of stripe centerlines from their smooth baseline.
class AnomalyDetector {
  final CvConfig config;

  const AnomalyDetector(this.config);

  // Returns normalized anomaly points and raw regions.
  ({List<Offset> points, List<AnomalyRegion> regions}) detect(
    List<List<double>> centerlines,
    int imageWidth,
    int imageHeight,
  ) {
    final points = <Offset>[];
    final regions = <AnomalyRegion>[];

    for (final track in centerlines) {
      final valid = <int>[];
      for (var y = 0; y < track.length; y++) {
        if (track[y] >= 0) valid.add(y);
      }
      if (valid.length < config.lineSmoothing * 2) continue;

      // Fit quadratic baseline through the stripe's centerline positions.
      final xs = valid.map((y) => track[y]).toList();
      final ys = valid.map((y) => y.toDouble()).toList();
      final coeffs = _fitQuadratic(ys, xs);

      // Find deviations from baseline.
      for (final y in valid) {
        final actual = track[y];
        final expected = coeffs[0] + coeffs[1] * y + coeffs[2] * y * y;
        final deviation = (actual - expected).abs();

        // anomalyThreshold is in pixels (not fraction of imageWidth).
        // Real dent deviations are 3–20px; default threshold = 4px.
        if (deviation > config.anomalyThreshold) {
          final nx = actual / imageWidth;
          final ny = y / imageHeight;
          points.add(Offset(nx, ny));
          regions.add(AnomalyRegion(
            normalizedX: nx,
            normalizedY: ny,
            magnitude: deviation,
          ));
        }
      }
    }

    return (points: points, regions: _mergeNearby(regions, imageWidth, imageHeight));
  }

  // Fit y = a + b*x + c*x^2 (least squares).
  List<double> _fitQuadratic(List<double> xs, List<double> ys) {
    final n = xs.length;
    if (n < 3) return [ys.isEmpty ? 0 : ys[0], 0, 0];

    // Build normal equations for [a, b, c].
    var s0 = n.toDouble();
    var s1 = 0.0, s2 = 0.0, s3 = 0.0, s4 = 0.0;
    var t0 = 0.0, t1 = 0.0, t2 = 0.0;

    for (var i = 0; i < n; i++) {
      final x = xs[i];
      final y = ys[i];
      s1 += x;
      s2 += x * x;
      s3 += x * x * x;
      s4 += x * x * x * x;
      t0 += y;
      t1 += x * y;
      t2 += x * x * y;
    }

    // Solve 3x3 system via Gaussian elimination (simplified).
    // For MVP, a linear fit is sufficient if quadratic is unstable.
    try {
      final det = s0 * (s2 * s4 - s3 * s3) -
          s1 * (s1 * s4 - s3 * s2) +
          s2 * (s1 * s3 - s2 * s2);
      if (det.abs() < 1e-10) throw Exception('singular');

      final a = (t0 * (s2 * s4 - s3 * s3) -
              s1 * (t1 * s4 - s3 * t2) +
              s2 * (t1 * s3 - s2 * t2)) /
          det;
      final b = (s0 * (t1 * s4 - s3 * t2) -
              t0 * (s1 * s4 - s3 * s2) +
              s2 * (s1 * t2 - t1 * s2)) /
          det;
      final c = (s0 * (s2 * t2 - t1 * s3) -
              s1 * (s1 * t2 - t1 * s2) +
              t0 * (s1 * s3 - s2 * s2)) /
          det;
      return [a, b, c];
    } catch (_) {
      // Fallback: linear fit.
      final meanX = s1 / n;
      final meanY = t0 / n;
      var cov = 0.0;
      var varX = 0.0;
      for (var i = 0; i < n; i++) {
        cov += (xs[i] - meanX) * (ys[i] - meanY);
        varX += pow(xs[i] - meanX, 2);
      }
      final slope = varX > 0 ? cov / varX : 0;
      return [(meanY - slope * meanX).toDouble(), slope.toDouble(), 0.0];
    }
  }

  List<AnomalyRegion> _mergeNearby(
      List<AnomalyRegion> regions, int width, int height) {
    if (regions.isEmpty) return regions;

    final mergeRadius = config.candidateMergeRadius / width;
    final merged = <AnomalyRegion>[];
    final used = List<bool>.filled(regions.length, false);

    for (var i = 0; i < regions.length; i++) {
      if (used[i]) continue;
      var sumX = regions[i].normalizedX;
      var sumY = regions[i].normalizedY;
      var sumMag = regions[i].magnitude;
      var count = 1;

      for (var j = i + 1; j < regions.length; j++) {
        if (used[j]) continue;
        final dx = regions[j].normalizedX - regions[i].normalizedX;
        final dy = regions[j].normalizedY - regions[i].normalizedY;
        if (sqrt(dx * dx + dy * dy) < mergeRadius) {
          sumX += regions[j].normalizedX;
          sumY += regions[j].normalizedY;
          sumMag += regions[j].magnitude;
          count++;
          used[j] = true;
        }
      }

      merged.add(AnomalyRegion(
        normalizedX: sumX / count,
        normalizedY: sumY / count,
        magnitude: sumMag / count,
      ));
      used[i] = true;
    }

    return merged;
  }
}
