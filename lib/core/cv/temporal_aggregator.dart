import 'dart:math';

import 'anomaly_detector.dart';
import 'cv_config.dart';
import 'cv_result.dart';
import 'dent_candidate.dart';

class TemporalAggregator {
  final CvConfig config;

  const TemporalAggregator(this.config);

  List<DentCandidate> aggregate(
      List<CvFrameResult> frames, int imageWidth, int imageHeight) {
    // Accumulator: tracks candidates being built across frames.
    final accum = <_Accumulator>[];
    final mergeRadius = config.candidateMergeRadius / imageWidth;

    for (var frameIdx = 0; frameIdx < frames.length; frameIdx++) {
      final regions = frames[frameIdx].anomalyPoints;

      for (final point in regions) {
        // Find closest existing accumulator within merge radius.
        _Accumulator? best;
        var bestDist = mergeRadius;

        for (final a in accum) {
          final dx = a.x - point.dx;
          final dy = a.y - point.dy;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < bestDist) {
            bestDist = dist;
            best = a;
          }
        }

        if (best != null) {
          best.update(point.dx, point.dy, frameIdx);
        } else {
          accum.add(_Accumulator(point.dx, point.dy, frameIdx));
        }
      }
    }

    // Convert accumulators to DentCandidates.
    final candidates = <DentCandidate>[];
    var idCounter = 0;

    for (final a in accum) {
      if (a.supportingFrames < config.minSupportingFrames) continue;

      final confidence = (a.supportingFrames / frames.length).clamp(0.0, 1.0);
      final radius = config.candidateMergeRadius / imageWidth;
      final severity = confidence > 0.6
          ? DentSeverity.large
          : confidence > 0.3
              ? DentSeverity.medium
              : DentSeverity.small;

      candidates.add(DentCandidate(
        id: 'dent_${++idCounter}',
        normalizedX: a.x,
        normalizedY: a.y,
        radiusEstimate: radius,
        severity: severity,
        confidence: confidence,
        firstFrame: a.firstFrame,
        lastFrame: a.lastFrame,
        supportingFrames: a.supportingFrames,
      ));
    }

    return candidates;
  }
}

class _Accumulator {
  double x;
  double y;
  int firstFrame;
  int lastFrame;
  int supportingFrames;
  int _updateCount;

  _Accumulator(this.x, this.y, int frame)
      : firstFrame = frame,
        lastFrame = frame,
        supportingFrames = 1,
        _updateCount = 1;

  void update(double nx, double ny, int frame) {
    // Running average of position.
    _updateCount++;
    x = (x * (_updateCount - 1) + nx) / _updateCount;
    y = (y * (_updateCount - 1) + ny) / _updateCount;
    lastFrame = frame;
    supportingFrames++;
  }
}
