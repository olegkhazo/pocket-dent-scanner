import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'light_pattern.dart';

part 'light_pattern_notifier.g.dart';

@riverpod
class LightPatternNotifier extends _$LightPatternNotifier {
  @override
  LightPattern build() => LightPattern(
        id: 'default',
        type: LightPatternType.verticalStripes,
        stripeWidth: 12,
        stripeSpacing: 12,
        brightness: 0.9,
        movementSpeed: 1.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

  void setType(LightPatternType type) =>
      state = state.copyWith(type: type, timestamp: _now());

  void setBrightness(double brightness) =>
      state = state.copyWith(brightness: brightness);

  void setStripeWidth(int width) =>
      state = state.copyWith(stripeWidth: width);

  void setStripeSpacing(int spacing) =>
      state = state.copyWith(stripeSpacing: spacing);

  void setMovementSpeed(double speed) =>
      state = state.copyWith(movementSpeed: speed);

  // Called by CV/camera layer to snapshot exact pattern at a frame timestamp.
  LightPattern snapshotAt({required int timestamp, required double phase}) =>
      state.copyWith(timestamp: timestamp, phase: phase);

  int _now() => DateTime.now().millisecondsSinceEpoch;
}
