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

  const CvFrameResult({
    required this.framePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.centerlines,
    required this.anomalyPoints,
  });
}

class CvResult {
  final List<DentCandidate> candidates;
  final List<CvFrameResult> frames;
  final double qualityScore;
  final int frameCount;

  const CvResult({
    required this.candidates,
    required this.frames,
    required this.qualityScore,
    required this.frameCount,
  });

  static const CvResult empty = CvResult(
    candidates: [],
    frames: [],
    qualityScore: 0,
    frameCount: 0,
  );
}
