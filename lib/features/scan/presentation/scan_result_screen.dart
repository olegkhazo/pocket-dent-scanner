import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cv/cv_result.dart';
import '../../../core/cv/dent_candidate.dart';

class ScanResultScreen extends StatelessWidget {
  final CvResult result;
  final String sessionDir;
  final String panelName;
  final int durationSeconds;

  const ScanResultScreen({
    super.key,
    required this.result,
    required this.sessionDir,
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
    final small =
        result.candidates.where((c) => c.severity == DentSeverity.small).length;
    final medium = result.candidates
        .where((c) => c.severity == DentSeverity.medium)
        .length;
    final large =
        result.candidates.where((c) => c.severity == DentSeverity.large).length;

    final representativeFrame =
        result.frames.isNotEmpty ? result.frames[result.frames.length ~/ 2] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(panelName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Debug Lab',
            onPressed: () =>
                context.goNamed('debug-lab', extra: sessionDir),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Frame with candidate overlay.
            if (representativeFrame != null)
              _FrameOverlay(
                framePath: representativeFrame.framePath,
                candidates: result.candidates,
              )
            else
              Container(
                height: 200,
                color: Colors.white10,
                child: const Center(
                    child: Text('No frames captured',
                        style: TextStyle(color: Colors.white54))),
              ),

            const SizedBox(height: 12),

            // Poor quality warning.
            if (result.qualityScore < 40)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        color: Colors.orangeAccent, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Poor scan quality — results may be unreliable. '
                        'Try finding the reflection angle and rescan.',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Summary.
            _SummaryCard(
              total: result.candidates.length,
              small: small,
              medium: medium,
              large: large,
              qualityScore: result.qualityScore,
              qualityLabel: result.qualityLabel,
              frameCount: result.frameCount,
              stableFrames: result.stableFrameCount,
              duration: _duration,
            ),

            const SizedBox(height: 24),

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
    );
  }
}

class _FrameOverlay extends StatelessWidget {
  final String framePath;
  final List<DentCandidate> candidates;

  const _FrameOverlay({
    required this.framePath,
    required this.candidates,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(framePath), fit: BoxFit.cover),
            CustomPaint(
              painter: _CandidateOverlayPainter(candidates),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateOverlayPainter extends CustomPainter {
  final List<DentCandidate> candidates;

  _CandidateOverlayPainter(this.candidates);

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in candidates) {
      final color = switch (c.severity) {
        DentSeverity.small => Colors.green,
        DentSeverity.medium => Colors.yellow,
        DentSeverity.large => Colors.red,
      };

      final center = Offset(c.normalizedX * size.width, c.normalizedY * size.height);
      final radius = c.radiusEstimate * size.width;

      canvas.drawCircle(
        center,
        radius.clamp(8, 40),
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      canvas.drawCircle(
        center,
        4,
        Paint()..color = color.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_CandidateOverlayPainter old) =>
      old.candidates != candidates;
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int small, medium, large;
  final int qualityScore;
  final ScanQualityLabel qualityLabel;
  final int frameCount;
  final int stableFrames;
  final String duration;

  const _SummaryCard({
    required this.total,
    required this.small,
    required this.medium,
    required this.large,
    required this.qualityScore,
    required this.qualityLabel,
    required this.frameCount,
    required this.stableFrames,
    required this.duration,
  });

  Color get _qualityColor {
    if (qualityScore >= 80) return Colors.greenAccent;
    if (qualityScore >= 60) return Colors.lightGreenAccent;
    if (qualityScore >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  total == 0
                      ? 'No dent candidates detected'
                      : '$total probable dent${total == 1 ? '' : 's'} detected',
                  style: TextStyle(
                    color: total == 0 ? Colors.white54 : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Quality badge.
              Column(
                children: [
                  Text('$qualityScore',
                      style: TextStyle(
                          color: _qualityColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text(qualityLabel.text,
                      style: TextStyle(color: _qualityColor, fontSize: 10)),
                ],
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            _Row('Small', small, Colors.green),
            _Row('Medium', medium, Colors.yellow),
            _Row('Large', large, Colors.red),
          ],
          const Divider(color: Colors.white12, height: 24),
          _Row('Frames analysed', frameCount, Colors.white54),
          _Row('Stable frames', stableFrames, Colors.white54),
          _Row('Duration', duration, Colors.white54),
          const SizedBox(height: 8),
          const Text(
            'Results show probable dent candidates — not confirmed measurements.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _Row(String label, Object value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            Text(value.toString(), style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      );
}
