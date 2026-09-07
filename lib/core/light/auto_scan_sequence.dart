import 'light_pattern.dart';

class AutoScanPhase {
  final LightPatternType type;
  final int stripeWidth;
  final int stripeSpacing;
  final int durationSeconds;
  final String label;

  const AutoScanPhase({
    required this.type,
    required this.stripeWidth,
    required this.stripeSpacing,
    required this.durationSeconds,
    required this.label,
  });
}

const List<AutoScanPhase> defaultAutoSequence = [
  AutoScanPhase(
    type: LightPatternType.wideVertical,
    stripeWidth: 28,
    stripeSpacing: 28,
    durationSeconds: 3,
    label: 'Wide',
  ),
  AutoScanPhase(
    type: LightPatternType.verticalStripes,
    stripeWidth: 12,
    stripeSpacing: 12,
    durationSeconds: 3,
    label: 'Medium',
  ),
  AutoScanPhase(
    type: LightPatternType.fineVertical,
    stripeWidth: 6,
    stripeSpacing: 6,
    durationSeconds: 3,
    label: 'Fine',
  ),
  AutoScanPhase(
    type: LightPatternType.horizontalStripes,
    stripeWidth: 12,
    stripeSpacing: 12,
    durationSeconds: 3,
    label: 'Horizontal',
  ),
];
