import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/camera/camera_service.dart';
import '../../../core/light/light_pattern_notifier.dart';
import '../../../core/light/light_pattern_widget.dart';
import '../domain/scan_panel.dart';

enum _ScanStatus { requesting, ready, scanning, stopping, error }

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
      await service.startRecording();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed++);
      });
      setState(() => _status = _ScanStatus.scanning);
    } catch (e) {
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = 'Camera error: $e';
      });
    }
  }

  Future<void> _stopScan() async {
    if (_status != _ScanStatus.scanning) return;
    setState(() => _status = _ScanStatus.stopping);
    _timer?.cancel();

    try {
      final service = ref.read(cameraServiceProvider);
      final xfile = await service.stopRecording();

      String? savedPath;
      if (xfile != null) {
        final dir = await getApplicationDocumentsDirectory();
        final scansDir = Directory('${dir.path}/scans');
        await scansDir.create(recursive: true);
        final dest = '${scansDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
        await File(xfile.path).copy(dest);
        savedPath = dest;
      }

      if (mounted) {
        context.goNamed('scan-saved', extra: {
          'path': savedPath,
          'panel': _panel.displayName,
          'duration': _elapsed,
        });
      }
    } catch (e) {
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = 'Failed to save scan: $e';
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

  String get _statusLabel => switch (_status) {
        _ScanStatus.requesting => 'REQUESTING CAMERA',
        _ScanStatus.ready => 'READY',
        _ScanStatus.scanning => _elapsed < 2 ? 'SCANNING — MOVE SLOWLY' : 'SCANNING',
        _ScanStatus.stopping => 'SAVING...',
        _ScanStatus.error => 'ERROR',
      };

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
          // Pattern fills entire screen.
          LightPatternWidget(pattern: pattern),

          // Overlay — minimal, non-intrusive.
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _StatusBadge(label: _statusLabel),
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
                    child: FilledButton.icon(
                      onPressed: _stopScan,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('STOP', style: TextStyle(fontSize: 16, letterSpacing: 2)),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(160, 48),
                      ),
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

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
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
