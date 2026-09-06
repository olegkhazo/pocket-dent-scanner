import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_service.g.dart';

class CameraService {
  CameraController? _controller;
  Timer? _captureTimer;
  final List<String> _capturedPaths = [];
  String? _sessionDir;
  bool _isCapturing = false;

  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isCapturing => _isCapturing;

  Future<void> initialize() async {
    final cameras = await availableCameras();

    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();

    // Lock camera settings for consistent scanning conditions.
    await _controller!.setExposureMode(ExposureMode.locked);
    await _controller!.setFocusMode(FocusMode.locked);
  }

  // Capture frames at ~5 FPS by calling takePicture() every 200ms.
  // Frames are saved as JPEG files in sessionDir.
  Future<void> startFrameCapture(String sessionDir) async {
    if (_controller == null || !isInitialized || _isCapturing) return;

    _sessionDir = sessionDir;
    _capturedPaths.clear();
    _isCapturing = true;

    final dir = Directory(sessionDir);
    await dir.create(recursive: true);

    _captureTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (!_isCapturing || _controller == null) return;
      try {
        final xfile = await _controller!.takePicture();
        final index = _capturedPaths.length.toString().padLeft(4, '0');
        final dest = '$sessionDir/frame_$index.jpg';
        await File(xfile.path).copy(dest);
        _capturedPaths.add(dest);
      } catch (_) {
        // Skip frames that fail (e.g. if camera is busy).
      }
    });
  }

  Future<List<String>> stopFrameCapture() async {
    _isCapturing = false;
    _captureTimer?.cancel();
    _captureTimer = null;

    final paths = List<String>.from(_capturedPaths);
    paths.sort();
    return paths;
  }

  void dispose() {
    _isCapturing = false;
    _captureTimer?.cancel();
    _controller?.dispose();
    _controller = null;
  }
}

@riverpod
CameraService cameraService(Ref ref) {
  final service = CameraService();
  ref.onDispose(service.dispose);
  return service;
}
