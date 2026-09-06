import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScanSavedScreen extends StatelessWidget {
  final String? filePath;
  final String panelName;
  final int durationSeconds;

  const ScanSavedScreen({
    super.key,
    required this.filePath,
    required this.panelName,
    required this.durationSeconds,
  });

  String get _duration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 72),
              const SizedBox(height: 24),
              const Text(
                'Scan Saved',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _InfoRow(label: 'Panel', value: panelName),
              _InfoRow(label: 'Duration', value: _duration),
              if (filePath != null)
                _InfoRow(
                  label: 'File',
                  value: filePath!.split('/').last,
                ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => context.goNamed('panel-select'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('New Scan'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
