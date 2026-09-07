import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

import 'anomaly_detector.dart';
import 'cv_config.dart';
import 'cv_result.dart';
import 'stripe_detector.dart';
import 'temporal_aggregator.dart';

class CvPipelineInput {
  final List<String> framePaths;
  final CvConfig config;

  const CvPipelineInput({required this.framePaths, required this.config});
}

class CvPipeline {
  // Max frames to process — keeps processing under a few seconds on device.
  static const int _maxFrames = 15;

  // Max width for processing — downscale for speed without losing stripe detail.
  static const int _maxProcessWidth = 480;

  static Future<CvResult> processFrames(CvPipelineInput input) async {
    final config = input.config;

    if (input.framePaths.isEmpty) return CvResult.empty;

    // Sample evenly distributed frames if there are too many.
    final total = input.framePaths.length;
    final paths = total <= _maxFrames
        ? input.framePaths
        : List.generate(
            _maxFrames,
            (i) => input.framePaths[(i * total ~/ _maxFrames)],
          );

    final stripeDetector = StripeDetector(config);
    final anomalyDetector = AnomalyDetector(config);

    final frameResults = <CvFrameResult>[];
    int originalWidth = 1, originalHeight = 1;

    for (final path in paths) {
      try {
        final bytes = await File(path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) continue;

        originalWidth = decoded.width;
        originalHeight = decoded.height;

        // Downscale for faster processing — stripe detection works fine at 480px.
        final scale = min(1.0, _maxProcessWidth / decoded.width);
        final working = scale < 1.0
            ? img.copyResize(
                decoded,
                width: (decoded.width * scale).round(),
                height: (decoded.height * scale).round(),
              )
            : decoded;

        final gray = img.grayscale(working);
        final centerlines = stripeDetector.detect(gray);

        final anomalyResult = anomalyDetector.detect(
          centerlines,
          gray.width,
          gray.height,
        );

        frameResults.add(CvFrameResult(
          framePath: path,
          imageWidth: gray.width,
          imageHeight: gray.height,
          centerlines: centerlines,
          anomalyPoints: anomalyResult.points,
        ));
      } catch (_) {
        // Skip corrupt or unreadable frames.
      }
    }

    if (frameResults.isEmpty) return CvResult.empty;

    final candidates = TemporalAggregator(config).aggregate(
      frameResults,
      frameResults.first.imageWidth,
      frameResults.first.imageHeight,
    );

    final qualityScore = _computeQuality(frameResults, paths.length);

    return CvResult(
      candidates: candidates,
      frames: frameResults,
      qualityScore: qualityScore,
      frameCount: frameResults.length,
    );
  }

  static double _computeQuality(List<CvFrameResult> frames, int totalFrames) {
    if (frames.isEmpty) return 0;
    final withStripes = frames.where((f) => f.centerlines.isNotEmpty).length;
    return (withStripes / totalFrames).clamp(0.0, 1.0);
  }
}
