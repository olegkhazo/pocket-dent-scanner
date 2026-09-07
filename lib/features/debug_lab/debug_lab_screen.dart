import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/cv/cv_config.dart';
import '../../core/cv/cv_pipeline.dart';
import '../../core/cv/cv_result.dart';

enum _DebugLayer { raw, grayscale, stripes, anomalies }

class DebugLabScreen extends StatefulWidget {
  final String? initialSessionDir;

  const DebugLabScreen({super.key, this.initialSessionDir});

  @override
  State<DebugLabScreen> createState() => _DebugLabScreenState();
}

class _DebugLabScreenState extends State<DebugLabScreen> {
  List<String> _scanDirs = [];
  String? _selectedDir;
  List<String> _framePaths = [];
  int _frameIndex = 0;
  _DebugLayer _layer = _DebugLayer.raw;
  CvResult? _cvResult;
  bool _processing = false;
  CvConfig _config = const CvConfig();

  @override
  void initState() {
    super.initState();
    _loadScanDirs().then((_) {
      if (widget.initialSessionDir != null) {
        _selectDir(widget.initialSessionDir!);
      }
    });
  }

  Future<void> _loadScanDirs() async {
    final base = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${base.path}/scans');
    if (!await scansDir.exists()) return;

    final dirs = await scansDir
        .list()
        .where((e) => e is Directory)
        .map((e) => e.path)
        .toList();
    dirs.sort((a, b) => b.compareTo(a)); // newest first
    setState(() => _scanDirs = dirs);
  }

  Future<void> _selectDir(String dir) async {
    final framesDir = Directory('$dir/frames').existsSync()
        ? Directory('$dir/frames')
        : Directory(dir);

    // Look for JPEG frames directly in the session dir.
    final files = await framesDir
        .list()
        .where((e) => e.path.endsWith('.jpg'))
        .map((e) => e.path)
        .toList();
    files.sort();

    setState(() {
      _selectedDir = dir;
      _framePaths = files;
      _frameIndex = 0;
      _cvResult = null;
    });

    if (files.isNotEmpty) _runCv();
  }

  Future<void> _runCv() async {
    if (_framePaths.isEmpty) return;
    setState(() => _processing = true);

    final input = CvPipelineInput(framePaths: _framePaths, config: _config);
    final result = await compute(CvPipeline.processFrames, input);

    setState(() {
      _cvResult = result;
      _processing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CV Debug Lab'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _selectedDir == null ? _buildScanList() : _buildViewer(),
    );
  }

  Widget _buildScanList() {
    if (_scanDirs.isEmpty) {
      return const Center(
        child: Text('No scans found.\nComplete a scan first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      itemCount: _scanDirs.length,
      itemBuilder: (ctx, i) {
        final name = _scanDirs[i].split('/').last;
        return ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(name),
          onTap: () => _selectDir(_scanDirs[i]),
        );
      },
    );
  }

  Widget _buildViewer() {
    final currentFrame =
        _framePaths.isNotEmpty ? _framePaths[_frameIndex] : null;

    final currentCvFrame = _cvResult != null &&
            _frameIndex < _cvResult!.frames.length
        ? _cvResult!.frames[_frameIndex]
        : null;

    return Column(
      children: [
        // Frame display.
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (currentFrame != null)
                Image.file(File(currentFrame), fit: BoxFit.contain),
              if (_processing)
                const Center(child: CircularProgressIndicator()),
              if (currentCvFrame != null && _layer == _DebugLayer.stripes)
                CustomPaint(
                  painter: _StripePainter(
                    currentCvFrame.centerlines,
                    currentCvFrame.imageWidth,
                    currentCvFrame.imageHeight,
                  ),
                ),
              if (currentCvFrame != null && _layer == _DebugLayer.anomalies)
                CustomPaint(
                  painter: _AnomalyPainter(currentCvFrame.anomalyPoints),
                ),
            ],
          ),
        ),

        // Layer selector.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SegmentedButton<_DebugLayer>(
            segments: const [
              ButtonSegment(value: _DebugLayer.raw, label: Text('Raw')),
              ButtonSegment(
                  value: _DebugLayer.stripes, label: Text('Stripes')),
              ButtonSegment(
                  value: _DebugLayer.anomalies, label: Text('Anomalies')),
            ],
            selected: {_layer},
            onSelectionChanged: (s) => setState(() => _layer = s.first),
            style: const ButtonStyle(
                visualDensity: VisualDensity(horizontal: -2, vertical: -2)),
          ),
        ),

        // Frame navigation.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _frameIndex > 0
                  ? () => setState(() => _frameIndex--)
                  : null,
            ),
            Text(
              '${_frameIndex + 1} / ${_framePaths.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _frameIndex < _framePaths.length - 1
                  ? () => setState(() => _frameIndex++)
                  : null,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _runCv,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reprocess'),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // CV info.
        if (_cvResult != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Candidates: ${_cvResult!.candidates.length}  '
              'Frames with stripes: ${_cvResult!.frames.where((f) => f.centerlines.isNotEmpty).length}/${_cvResult!.frameCount}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _StripePainter extends CustomPainter {
  final List<List<double>> centerlines;
  final int imageWidth;
  final int imageHeight;

  _StripePainter(this.centerlines, this.imageWidth, this.imageHeight);

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth == 0 || imageHeight == 0) return;
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;

    for (final track in centerlines) {
      Offset? prev;
      for (var y = 0; y < track.length; y++) {
        if (track[y] < 0) {
          prev = null;
          continue;
        }
        final pt = Offset(
          track[y] / imageWidth * size.width,
          y / imageHeight * size.height,
        );
        if (prev != null) canvas.drawLine(prev, pt, paint);
        prev = pt;
      }
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) =>
      old.centerlines != centerlines ||
      old.imageWidth != imageWidth ||
      old.imageHeight != imageHeight;
}

class _AnomalyPainter extends CustomPainter {
  final List<dynamic> anomalyPoints;

  _AnomalyPainter(this.anomalyPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.8)
      ..strokeWidth = 1;

    for (final pt in anomalyPoints) {
      final offset = Offset(pt.dx * size.width, pt.dy * size.height);
      canvas.drawCircle(offset, 4, paint);
    }
  }

  @override
  bool shouldRepaint(_AnomalyPainter old) =>
      old.anomalyPoints != anomalyPoints;
}
