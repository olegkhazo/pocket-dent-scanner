import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cv/cv_config.dart';
import '../../../core/cv/cv_pipeline.dart';
import '../../../core/cv/cv_result.dart';
import '../../../features/scan_history/scan_meta.dart';
import '../../../features/settings/app_settings.dart';

class ScanProcessingScreen extends ConsumerStatefulWidget {
  final List<String> framePaths;
  final String sessionDir;
  final String panelName;
  final int durationSeconds;

  const ScanProcessingScreen({
    super.key,
    required this.framePaths,
    required this.sessionDir,
    required this.panelName,
    required this.durationSeconds,
  });

  @override
  ConsumerState<ScanProcessingScreen> createState() =>
      _ScanProcessingScreenState();
}

class _ScanProcessingScreenState extends ConsumerState<ScanProcessingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
  }

  Future<void> _process() async {
    final settings = ref.read(appSettingsProvider);

    final input = CvPipelineInput(
      framePaths: widget.framePaths,
      config: CvConfig(
        anomalyThreshold: settings.anomalyThreshold,
        minSupportingFrames: settings.minSupportingFrames,
      ),
      maxFrames: settings.processingQuality.maxFrames,
      processWidth: settings.processingQuality.processWidth,
    );

    final result = await compute(CvPipeline.processFrames, input);

    // Pick a representative thumbnail (middle frame).
    String? thumbPath;
    if (result.frames.isNotEmpty) {
      thumbPath = result.frames[result.frames.length ~/ 2].framePath;
    }

    // Save scan metadata for history.
    final meta = ScanMeta(
      id: widget.sessionDir.split('/').last,
      panelName: widget.panelName,
      createdAt: DateTime.now(),
      durationSeconds: widget.durationSeconds,
      frameCount: result.frameCount,
      candidateCount: result.candidates.length,
      qualityScore: result.qualityScore,
      qualityLabel: result.qualityLabel.text,
      sessionDir: widget.sessionDir,
      thumbnailPath: thumbPath,
    );
    await meta.saveTo(widget.sessionDir);

    // Delete raw frames if user opted out of keeping them.
    if (!settings.keepDebugFrames) {
      for (final path in widget.framePaths) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
    }

    if (mounted) {
      context.goNamed('scan-result', extra: {
        'result': result,
        'sessionDir': widget.sessionDir,
        'panel': widget.panelName,
        'duration': widget.durationSeconds,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white54),
            const SizedBox(height: 24),
            const Text('Analysing scan...',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '${widget.framePaths.length} frames',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
