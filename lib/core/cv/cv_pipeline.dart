import 'dart:io';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'anomaly_detector.dart';
import 'cv_config.dart';
import 'cv_result.dart';
import 'dent_candidate.dart';
import 'stripe_detector.dart';
import 'temporal_aggregator.dart';

class CvPipelineInput {
  final List<String> framePaths;
  final CvConfig config;

  const CvPipelineInput({required this.framePaths, required this.config});
}

class CvPipeline {
  // Top-level function for use with Flutter's compute().
  // Must be a top-level or static function to run in an isolate.
  static Future<CvResult> processFrames(CvPipelineInput input) async {
    final config = input.config;
    final paths = input.framePaths;

    if (paths.isEmpty) return CvResult.empty;

    final stripeDetector = StripeDetector(config);
    final anomalyDetector = AnomalyDetector(config);

    final frameResults = <CvFrameResult>[];
    int imageWidth = 1, imageHeight = 1;

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      try {
        final bytes = await File(path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) continue;

        imageWidth = decoded.width;
        imageHeight = decoded.height;

        // Convert to grayscale.
        final gray = img.grayscale(decoded);

        // Detect stripe centerlines.
        final centerlines = stripeDetector.detect(gray);

        // Detect anomalies.
        final result = anomalyDetector.detect(
          centerlines,
          imageWidth,
          imageHeight,
        );

        frameResults.add(CvFrameResult(
          framePath: path,
          centerlines: centerlines,
          anomalyPoints: result.points,
        ));
      } catch (_) {
        // Skip corrupt frames.
      }
    }

    if (frameResults.isEmpty) return CvResult.empty;

    // Aggregate across frames.
    final candidates = TemporalAggregator(config).aggregate(
      frameResults,
      imageWidth,
      imageHeight,
    );

    final qualityScore = _computeQuality(frameResults, paths.length);

    return CvResult(
      candidates: candidates,
      frames: frameResults,
      qualityScore: qualityScore,
      frameCount: frameResults.length,
    );
  }

  static double _computeQuality(
      List<CvFrameResult> frames, int totalFrames) {
    if (frames.isEmpty) return 0;

    // Quality = fraction of frames with detected stripes.
    final framesWithStripes =
        frames.where((f) => f.centerlines.isNotEmpty).length;
    return (framesWithStripes / totalFrames).clamp(0.0, 1.0);
  }
}
