import 'package:camera/camera.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_service.g.dart';

class CameraService {
  CameraController? _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isRecording => _controller?.value.isRecordingVideo ?? false;

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

  Future<void> startRecording() async {
    if (_controller == null || !isInitialized || isRecording) return;
    await _controller!.startVideoRecording();
  }

  Future<XFile?> stopRecording() async {
    if (_controller == null || !isRecording) return null;
    return _controller!.stopVideoRecording();
  }

  void dispose() {
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
