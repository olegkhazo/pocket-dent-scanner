import 'dart:ui';

import 'dent_candidate.dart';

class CvFrameResult {
  final String framePath;
  final int imageWidth;
  final int imageHeight;

  // centerlines[stripe_idx][row] = x position in pixels.
  final List<List<double>> centerlines;

  // Normalized (0..1) anomaly points on this frame.
  final List<Offset> anomalyPoints;

  // True if frame was stable enough to include in temporal aggregation.
  final bool isStable;

  const CvFrameResult({
    required this.framePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.centerlines,
    required this.anomalyPoints,
    this.isStable = true,
  });
}

enum ScanQualityLabel { poor, acceptable, good, excellent }

extension ScanQualityLabelExt on ScanQualityLabel {
  String get text => switch (this) {
        ScanQualityLabel.poor => 'Poor',
        ScanQualityLabel.acceptable => 'Acceptable',
        ScanQualityLabel.good => 'Good',
        ScanQualityLabel.excellent => 'Excellent',
      };
}

class CvResult {
  final List<DentCandidate> candidates;
  final List<CvFrameResult> frames;

  // 0..100
  final int qualityScore;
  final ScanQualityLabel qualityLabel;
  final int frameCount;
  final int stableFrameCount;

  const CvResult({
    required this.candidates,
    required this.frames,
    required this.qualityScore,
    required this.qualityLabel,
    required this.frameCount,
    required this.stableFrameCount,
  });

  static const CvResult empty = CvResult(
    candidates: [],
    frames: [],
    qualityScore: 0,
    qualityLabel: ScanQualityLabel.poor,
    frameCount: 0,
    stableFrameCount: 0,
  );
}
