import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class HiddenCameraService {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  bool _isRecording = false;
  Timer? _segmentTimer;
  final List<String> _recordedVideoPaths = [];

  bool get isRecording => _isRecording;
  CameraController? get controller => _controller;
  List<String> get recordedVideoPaths => List.unmodifiable(_recordedVideoPaths);

  /// Initializes available cameras silently
  Future<bool> initializeCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) return false;

      // Prefer back camera, or front if back is unavailable
      final camera = _availableCameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _availableCameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.low, // Changed from medium to low for battery optimization
        enableAudio: true,
      );

      await _controller!.initialize();
      return true;
    } catch (e) {
      debugPrint('Silent camera init failed: $e');
      return false;
    }
  }

  /// Starts rolling segmented background recording (e.g. 60s per chunk)
  Future<void> startHiddenRecording({
    int segmentDurationSeconds = 60,
    Function(String videoPath)? onSegmentCompleted,
  }) async {
    if (_isRecording) return;

    if (_controller == null || !_controller!.value.isInitialized) {
      bool initialized = await initializeCamera();
      if (!initialized) return;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;

      // Set rolling timer to split into 60s segments for safe cloud syncing
      _segmentTimer = Timer.periodic(
        Duration(seconds: segmentDurationSeconds),
        (timer) async {
          if (!_isRecording) {
            timer.cancel();
            return;
          }
          final path = await _stopAndSaveCurrentSegment();
          if (path != null) {
            _recordedVideoPaths.add(path);
            onSegmentCompleted?.call(path);
          }
          // Restart recording next segment
          if (_controller != null && _controller!.value.isInitialized) {
            await _controller!.startVideoRecording();
          }
        },
      );
    } catch (e) {
      debugPrint('Error starting hidden recording: $e');
      _isRecording = false;
    }
  }

  Future<String?> _stopAndSaveCurrentSegment() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      return null;
    }
    try {
      final xFile = await _controller!.stopVideoRecording();
      return xFile.path;
    } catch (e) {
      debugPrint('Error saving video segment: $e');
      return null;
    }
  }

  /// Stops hidden recording and releases hardware
  Future<List<String>> stopHiddenRecording() async {
    _segmentTimer?.cancel();
    _segmentTimer = null;

    if (_isRecording) {
      final lastPath = await _stopAndSaveCurrentSegment();
      if (lastPath != null) {
        _recordedVideoPaths.add(lastPath);
      }
      _isRecording = false;
    }

    return _recordedVideoPaths;
  }

  void dispose() {
    _segmentTimer?.cancel();
    _controller?.dispose();
  }
}
