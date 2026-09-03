import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/light/light_pattern.dart';
import '../../core/light/light_pattern_notifier.dart';

class LightTestControls extends ConsumerWidget {
  const LightTestControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pattern = ref.watch(lightPatternNotifierProvider);
    final notifier = ref.read(lightPatternNotifierProvider.notifier);

    return Material(
      color: Colors.black87,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _PatternTypeSelector(
              selected: pattern.type,
              onChanged: notifier.setType,
            ),
            const SizedBox(height: 16),
            _LabeledSlider(
              label: 'Brightness',
              value: pattern.brightness,
              min: 0.3,
              max: 1.0,
              divisions: 14,
              displayValue: '${(pattern.brightness * 100).round()}%',
              onChanged: notifier.setBrightness,
            ),
            _LabeledSlider(
              label: 'Stripe width',
              value: pattern.stripeWidth.toDouble(),
              min: 2,
              max: 60,
              divisions: 58,
              displayValue: '${pattern.stripeWidth}px',
              onChanged: (v) => notifier.setStripeWidth(v.round()),
            ),
            _LabeledSlider(
              label: 'Stripe spacing',
              value: pattern.stripeSpacing.toDouble(),
              min: 2,
              max: 60,
              divisions: 58,
              displayValue: '${pattern.stripeSpacing}px',
              onChanged: (v) => notifier.setStripeSpacing(v.round()),
            ),
            if (pattern.type == LightPatternType.movingVertical ||
                pattern.type == LightPatternType.movingHorizontal)
              _LabeledSlider(
                label: 'Speed',
                value: pattern.movementSpeed,
                min: 0.1,
                max: 5.0,
                divisions: 49,
                displayValue: pattern.movementSpeed.toStringAsFixed(1),
                onChanged: notifier.setMovementSpeed,
              ),
          ],
        ),
      ),
    );
  }
}

class _PatternTypeSelector extends StatelessWidget {
  final LightPatternType selected;
  final ValueChanged<LightPatternType> onChanged;

  const _PatternTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _labels = <LightPatternType, String>{
    LightPatternType.verticalStripes: 'Vertical',
    LightPatternType.horizontalStripes: 'Horizontal',
    LightPatternType.fineVertical: 'Fine',
    LightPatternType.wideVertical: 'Wide',
    LightPatternType.movingVertical: 'Moving V',
    LightPatternType.movingHorizontal: 'Moving H',
    LightPatternType.checkerboard: 'Checker',
    LightPatternType.phaseShiftedVertical: 'Phase',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: _labels.entries.map((entry) {
          final isSelected = entry.key == selected;
          return ChoiceChip(
            label: Text(entry.value),
            selected: isSelected,
            onSelected: (_) => onChanged(entry.key),
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(displayValue,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
