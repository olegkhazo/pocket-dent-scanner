import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/light/light_pattern.dart';
import 'app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsNotifierProvider);
    final notifier = ref.read(appSettingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('General'),
          _SliderTile(
            label: 'Default brightness',
            value: settings.defaultBrightness,
            min: 0.3,
            max: 1.0,
            displayValue: '${(settings.defaultBrightness * 100).round()}%',
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(defaultBrightness: v)),
          ),
          _SwitchTile(
            label: 'Keep debug frames',
            subtitle: 'Save individual frames for Debug Lab inspection',
            value: settings.keepDebugFrames,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(keepDebugFrames: v)),
          ),
          const SizedBox(height: 16),
          _SectionHeader('Processing Quality'),
          ...ProcessingQuality.values.map((q) => RadioListTile<ProcessingQuality>(
                title: Text(q.label),
                subtitle: Text(
                  '${q.maxFrames} frames  •  ${q.processWidth}px',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                value: q,
                groupValue: settings.processingQuality,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(processingQuality: v)),
              )),
          const SizedBox(height: 16),
          _SectionHeader('Developer'),
          _SliderTile(
            label: 'Anomaly threshold',
            value: settings.anomalyThreshold,
            min: 0.05,
            max: 1.0,
            displayValue: settings.anomalyThreshold.toStringAsFixed(2),
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(anomalyThreshold: v)),
          ),
          _SliderTile(
            label: 'Min supporting frames',
            value: settings.minSupportingFrames.toDouble(),
            min: 1,
            max: 10,
            displayValue: '${settings.minSupportingFrames}',
            onChanged: (v) => notifier
                .update((s) => s.copyWith(minSupportingFrames: v.round())),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await notifier.resetDefaults();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              }
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Reset to Defaults'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min, max;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
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
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(displayValue,
                style:
                    const TextStyle(color: Colors.white, fontFamily: 'monospace')),
          ],
        ),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: Colors.white38, fontSize: 12))
          : null,
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
