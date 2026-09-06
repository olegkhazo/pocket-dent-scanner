import 'dart:ui';

import 'dent_candidate.dart';

class CvFrameResult {
  final String framePath;

  // centerlines[stripe_idx] = list of x positions indexed by row.
  final List<List<double>> centerlines;

  // Normalized (0..1) anomaly points on this frame.
  final List<Offset> anomalyPoints;

  const CvFrameResult({
    required this.framePath,
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
