import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'anomaly_detector.dart';
import 'cv_config.dart';
import 'cv_result.dart';
import 'stripe_detector.dart';
import 'temporal_aggregator.dart';

class CvPipelineInput {
  final List<String> framePaths;
  final CvConfig config;
  final int maxFrames;
  final int processWidth;

  const CvPipelineInput({
    required this.framePaths,
    required this.config,
    this.maxFrames = 30,
    this.processWidth = 480,
  });
}

class CvPipeline {
  static Future<CvResult> processFrames(CvPipelineInput input) async {
    if (input.framePaths.isEmpty) return CvResult.empty;

    // Sample evenly distributed frames.
    final total = input.framePaths.length;
    final paths = total <= input.maxFrames
        ? input.framePaths
        : List.generate(
            input.maxFrames,
            (i) => input.framePaths[(i * total ~/ input.maxFrames)],
          );

    final stripeDetector = StripeDetector(input.config);
    final anomalyDetector = AnomalyDetector(input.config);

    final frameResults = <CvFrameResult>[];
    img.Image? prevThumb;

    for (final path in paths) {
      try {
        final bytes = await File(path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) continue;

        // Downscale for processing.
        final scale = min(1.0, input.processWidth / decoded.width);
        final working = scale < 1.0
            ? img.copyResize(decoded,
                width: (decoded.width * scale).round(),
                height: (decoded.height * scale).round())
            : decoded;

        // Frame stabilization: compute motion vs previous frame using MAD.
        final thumb = img.copyResize(img.grayscale(working), width: 64, height: 64);
        final motionScore = prevThumb != null ? _mad(prevThumb, thumb) : 0.0;
        prevThumb = thumb;

        final isStable = motionScore <= input.config.maxCameraMotion;

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
          isStable: isStable,
        ));
      } catch (_) {
        // Skip corrupt frames.
      }
    }

    if (frameResults.isEmpty) return CvResult.empty;

    // Only stable frames contribute to dent candidates.
    final stableFrames = frameResults.where((f) => f.isStable).toList();

    final candidates = stableFrames.isEmpty
        ? <dynamic>[]
        : TemporalAggregator(input.config).aggregate(
            stableFrames,
            stableFrames.first.imageWidth,
            stableFrames.first.imageHeight,
          );

    final quality = _computeQuality(frameResults, stableFrames.length, paths.length);

    return CvResult(
      candidates: candidates.cast(),
      frames: frameResults,
      qualityScore: quality.score,
      qualityLabel: quality.label,
      frameCount: frameResults.length,
      stableFrameCount: stableFrames.length,
    );
  }

  // Mean absolute difference between two 64×64 grayscale thumbnails.
  static double _mad(img.Image a, img.Image b) {
    var sum = 0.0;
    final pixels = a.width * a.height;
    for (var y = 0; y < a.height; y++) {
      for (var x = 0; x < a.width; x++) {
        sum += (a.getPixel(x, y).luminance - b.getPixel(x, y).luminance).abs();
      }
    }
    return sum / pixels;
  }

  static ({int score, ScanQualityLabel label}) _computeQuality(
    List<CvFrameResult> frames,
    int stableCount,
    int sampledTotal,
  ) {
    if (frames.isEmpty) return (score: 0, label: ScanQualityLabel.poor);

    // Metric 1: stripe visibility — fraction of frames that have stripes.
    final withStripes = frames.where((f) => f.centerlines.isNotEmpty).length;
    final stripeVisibility = withStripes / frames.length;

    // Metric 2: motion stability — fraction of stable frames.
    final motionStability = frames.isEmpty ? 0.0 : stableCount / frames.length;

    // Metric 3: signal strength — avg stripe count per frame, capped at 1.0 for 10+ stripes.
    final avgStripes = frames.isEmpty
        ? 0.0
        : frames.map((f) => f.centerlines.length).reduce((a, b) => a + b) /
            frames.length;
    final signalStrength = (avgStripes / 10.0).clamp(0.0, 1.0);

    // Metric 4: frame coverage — how many frames were processed vs total collected.
    final frameCoverage = (frames.length / max(1, sampledTotal)).clamp(0.0, 1.0);

    // Weighted average → 0..100.
    final raw = (stripeVisibility * 0.40 +
            motionStability * 0.30 +
            signalStrength * 0.20 +
            frameCoverage * 0.10) *
        100;
    final score = raw.round().clamp(0, 100);

    final label = score >= 80
        ? ScanQualityLabel.excellent
        : score >= 60
            ? ScanQualityLabel.good
            : score >= 40
                ? ScanQualityLabel.acceptable
                : ScanQualityLabel.poor;

    return (score: score, label: label);
  }
}
