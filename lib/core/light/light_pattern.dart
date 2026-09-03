import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'light_pattern.freezed.dart';
part 'light_pattern.g.dart';

enum LightPatternType {
  verticalStripes,
  horizontalStripes,
  fineVertical,
  wideVertical,
  movingVertical,
  movingHorizontal,
  checkerboard,
  phaseShiftedVertical,
}

// Stores Color as ARGB int for JSON serialization.
class _ColorConverter implements JsonConverter<Color, int> {
  const _ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color color) => color.toARGB32();
}

@freezed
class LightPattern with _$LightPattern {
  const factory LightPattern({
    required String id,
    required LightPatternType type,
    @Default(8) int stripeWidth,
    @Default(8) int stripeSpacing,
    @Default(1.0) double brightness,
    @_ColorConverter() @Default(Color(0xFFFFFFFF)) Color foregroundColor,
    @_ColorConverter() @Default(Color(0xFF000000)) Color backgroundColor,
    @Default(0.0) double movementSpeed,
    @Default(0.0) double phase,
    @Default(0.0) double orientation,
    required int timestamp,
  }) = _LightPattern;

  factory LightPattern.fromJson(Map<String, dynamic> json) =>
      _$LightPatternFromJson(json);
}
