import 'package:freezed_annotation/freezed_annotation.dart';

part 'cv_config.freezed.dart';
part 'cv_config.g.dart';

@freezed
class CvConfig with _$CvConfig {
  const factory CvConfig({
    @Default(3) int blurRadius,
    @Default(2.0) double contrastLimit,
    @Default(11) int thresholdBlockSize,
    @Default(2.0) double thresholdC,
    @Default(20) int minStripeLength,
    @Default(5) int maxStripeGap,
    @Default(3) int lineSmoothing,
    @Default(0.3) double anomalyThreshold,
    @Default(3) int minSupportingStripes,
    @Default(3) int minSupportingFrames,
    @Default(15) int candidateMergeRadius,
    @Default(30.0) double maxCameraMotion,
  }) = _CvConfig;

  factory CvConfig.fromJson(Map<String, dynamic> json) =>
      _$CvConfigFromJson(json);
}
