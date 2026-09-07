import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/light/light_pattern.dart';

part 'app_settings.g.dart';

enum ProcessingQuality { fast, balanced, high }

extension ProcessingQualitySettings on ProcessingQuality {
  String get label => switch (this) {
        ProcessingQuality.fast => 'Fast',
        ProcessingQuality.balanced => 'Balanced',
        ProcessingQuality.high => 'High Quality',
      };

  int get maxFrames => switch (this) {
        ProcessingQuality.fast => 15,
        ProcessingQuality.balanced => 30,
        ProcessingQuality.high => 60,
      };

  int get processWidth => switch (this) {
        ProcessingQuality.fast => 320,
        ProcessingQuality.balanced => 480,
        ProcessingQuality.high => 640,
      };
}

class AppSettings {
  final double defaultBrightness;
  final LightPatternType defaultPatternType;
  final bool keepDebugFrames;
  final ProcessingQuality processingQuality;
  final double anomalyThreshold;
  final int minSupportingFrames;
  final bool cvDebugMode;

  const AppSettings({
    this.defaultBrightness = 0.9,
    this.defaultPatternType = LightPatternType.verticalStripes,
    this.keepDebugFrames = true,
    this.processingQuality = ProcessingQuality.balanced,
    this.anomalyThreshold = 4.0,
    this.minSupportingFrames = 3,
    this.cvDebugMode = false,
  });

  AppSettings copyWith({
    double? defaultBrightness,
    LightPatternType? defaultPatternType,
    bool? keepDebugFrames,
    ProcessingQuality? processingQuality,
    double? anomalyThreshold,
    int? minSupportingFrames,
    bool? cvDebugMode,
  }) =>
      AppSettings(
        defaultBrightness: defaultBrightness ?? this.defaultBrightness,
        defaultPatternType: defaultPatternType ?? this.defaultPatternType,
        keepDebugFrames: keepDebugFrames ?? this.keepDebugFrames,
        processingQuality: processingQuality ?? this.processingQuality,
        anomalyThreshold: anomalyThreshold ?? this.anomalyThreshold,
        minSupportingFrames: minSupportingFrames ?? this.minSupportingFrames,
        cvDebugMode: cvDebugMode ?? this.cvDebugMode,
      );
}

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      defaultBrightness: prefs.getDouble('brightness') ?? 0.9,
      defaultPatternType: LightPatternType.values[prefs.getInt('patternType') ?? 0],
      keepDebugFrames: prefs.getBool('keepFrames') ?? true,
      processingQuality:
          ProcessingQuality.values[prefs.getInt('quality') ?? 1],
      anomalyThreshold: prefs.getDouble('anomalyThreshold') ?? 0.3,
      minSupportingFrames: prefs.getInt('minFrames') ?? 3,
      cvDebugMode: prefs.getBool('cvDebug') ?? false,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('brightness', state.defaultBrightness);
    await prefs.setInt('patternType', state.defaultPatternType.index);
    await prefs.setBool('keepFrames', state.keepDebugFrames);
    await prefs.setInt('quality', state.processingQuality.index);
    await prefs.setDouble('anomalyThreshold', state.anomalyThreshold);
    await prefs.setInt('minFrames', state.minSupportingFrames);
    await prefs.setBool('cvDebug', state.cvDebugMode);
  }

  Future<void> update(AppSettings Function(AppSettings) updater) async {
    state = updater(state);
    await _save();
  }

  Future<void> resetDefaults() async {
    state = const AppSettings();
    await _save();
  }
}
