import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/camera/camera_service.dart';
import '../../../core/light/auto_scan_sequence.dart';
import '../../../core/light/light_pattern.dart';
import '../../../core/light/light_pattern_notifier.dart';
import '../../../core/light/light_pattern_widget.dart';
import '../domain/scan_panel.dart';

enum _ScanStatus { requesting, scanning, stopping, error }

class ScanScreen extends ConsumerStatefulWidget {
  final String panelName;

  const ScanScreen({super.key, required this.panelName});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  _ScanStatus _status = _ScanStatus.requesting;
  int _elapsed = 0;
  Timer? _timer;
  String? _errorMessage;
  String? _sessionDir;

  // Auto scan mode.
  bool _autoMode = false;
  int _autoPhaseIndex = 0;
  int _autoPhaseElapsed = 0;

  PanelType get _panel {
    try {
      return PanelType.values.byName(widget.panelName);
    } catch (_) {
      return PanelType.other;
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = 'Camera permission denied.\nGo to Settings to allow.';
      });
      return;
    }

    try {
      final service = ref.read(cameraServiceProvider);
      await service.initialize();

      final dir = await getApplicationDocumentsDirectory();
      _sessionDir =
          '${dir.path}/scans/${DateTime.now().millisecondsSinceEpoch}';

      await service.startFrameCapture(_sessionDir!);

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _elapsed++;
          if (_autoMode) _tickAutoMode();
        });
      });

      setState(() => _status = _ScanStatus.scanning);
    } catch (e) {
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = 'Camera error: $e';
      });
    }
  }

  void _toggleAutoMode() {
    if (_status != _ScanStatus.scanning) return;
    setState(() {
      _autoMode = !_autoMode;
      if (_autoMode) {
        _autoPhaseIndex = 0;
        _autoPhaseElapsed = 0;
        _applyAutoPhase(_autoPhaseIndex);
      }
    });
  }

  void _tickAutoMode() {
    _autoPhaseElapsed++;
    final phase = defaultAutoSequence[_autoPhaseIndex];

    if (_autoPhaseElapsed >= phase.durationSeconds) {
      final nextIndex = _autoPhaseIndex + 1;
      if (nextIndex >= defaultAutoSequence.length) {
        // Auto sequence complete — stop scan.
        _stopScan();
      } else {
        _autoPhaseIndex = nextIndex;
        _autoPhaseElapsed = 0;
        _applyAutoPhase(_autoPhaseIndex);
      }
    }
  }

  void _applyAutoPhase(int index) {
    final phase = defaultAutoSequence[index];
    final notifier = ref.read(lightPatternProvider.notifier);
    notifier.setType(phase.type);
    notifier.setStripeWidth(phase.stripeWidth);
    notifier.setStripeSpacing(phase.stripeSpacing);
  }

  Future<void> _stopScan() async {
    if (_status != _ScanStatus.scanning) return;
    setState(() => _status = _ScanStatus.stopping);
    _timer?.cancel();
    _autoMode = false;

    try {
      final service = ref.read(cameraServiceProvider);
      final framePaths = await service.stopFrameCapture();

      if (mounted) {
        context.goNamed('scan-processing', extra: {
          'framePaths': framePaths,
          'sessionDir': _sessionDir,
          'panel': _panel.displayName,
          'duration': _elapsed,
        });
      }
    } catch (e) {
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = 'Failed to stop scan: $e';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  String get _statusLabel {
    if (_autoMode && _status == _ScanStatus.scanning) {
      final phase = defaultAutoSequence[_autoPhaseIndex];
      return 'AUTO  ${_autoPhaseIndex + 1}/${defaultAutoSequence.length}  ${phase.label}';
    }
    return switch (_status) {
      _ScanStatus.requesting => 'REQUESTING CAMERA',
      _ScanStatus.scanning =>
        _elapsed < 2 ? 'SCANNING — MOVE SLOWLY' : 'SCANNING',
      _ScanStatus.stopping => 'SAVING...',
      _ScanStatus.error => 'ERROR',
    };
  }

  String get _timerLabel {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pattern = ref.watch(lightPatternProvider);

    if (_status == _ScanStatus.error) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Unknown error',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          LightPatternWidget(pattern: pattern),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _StatusBadge(label: _statusLabel, isAuto: _autoMode),
                const SizedBox(height: 8),
                if (_status == _ScanStatus.scanning ||
                    _status == _ScanStatus.stopping)
                  Text(
                    _timerLabel,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                const Spacer(),
                if (_status == _ScanStatus.scanning)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // AUTO toggle.
                        _ScanButton(
                          label: _autoMode ? 'MANUAL' : 'AUTO',
                          icon: _autoMode
                              ? Icons.touch_app_outlined
                              : Icons.auto_mode,
                          color: _autoMode
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white38,
                          onTap: _toggleAutoMode,
                        ),
                        const SizedBox(width: 16),
                        // STOP button.
                        _ScanButton(
                          label: 'STOP',
                          icon: Icons.stop_circle_outlined,
                          color: Colors.white70,
                          onTap: _stopScan,
                          primary: true,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isAuto;

  const _StatusBadge({required this.label, this.isAuto = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isAuto
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
            : Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: isAuto
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6))
            : null,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool primary;

  const _ScanButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: primary
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black38,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 14, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}
