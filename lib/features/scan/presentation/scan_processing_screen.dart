import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cv/cv_config.dart';
import '../../../core/cv/cv_pipeline.dart';
import '../../../core/cv/cv_result.dart';

class ScanProcessingScreen extends StatefulWidget {
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
  State<ScanProcessingScreen> createState() => _ScanProcessingScreenState();
}

class _ScanProcessingScreenState extends State<ScanProcessingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
  }

  Future<void> _process() async {
    final input = CvPipelineInput(
      framePaths: widget.framePaths,
      config: const CvConfig(),
    );

    // Run CV pipeline in a separate isolate so UI stays responsive.
    final result = await compute(CvPipeline.processFrames, input);

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
            const Text(
              'Analysing scan...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
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
