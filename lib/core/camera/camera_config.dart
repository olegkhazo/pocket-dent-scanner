import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera_config.freezed.dart';
part 'camera_config.g.dart';

@freezed
class CameraConfig with _$CameraConfig {
  const factory CameraConfig({
    @Default('1920x1080') String resolution,
    @Default(30) int targetFps,
    @Default(true) bool lockExposure,
    @Default(true) bool lockFocus,
    @Default(true) bool lockWhiteBalance,
    @Default(false) bool enableBeautyProcessing,
  }) = _CameraConfig;

  factory CameraConfig.fromJson(Map<String, dynamic> json) =>
      _$CameraConfigFromJson(json);
}
