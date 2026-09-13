import 'dart:async';

enum PresenceStatus {
  idle,
  presenceDetected,
  presenceLost,
}

abstract class PresenceDetector {
  /// Stream of presence events
  Stream<PresenceStatus> get presenceStream;

  /// Current presence state
  bool get isPresenceDetected;

  /// Start monitoring for presence (Camera, mmWave sensor, or touch)
  Future<void> start();

  /// Pause/Stop monitoring to conserve resources
  Future<void> stop();

  /// Notify manual interaction (touch / wake event)
  void notifyInteraction();

  void dispose();
}

/// Base touch/tap presence detector (always active fallback)
class TapToWakeDetector implements PresenceDetector {
  final _controller = StreamController<PresenceStatus>.broadcast();
  bool _detected = false;
  Timer? _lostTimer;

  @override
  Stream<PresenceStatus> get presenceStream => _controller.stream;

  @override
  bool get isPresenceDetected => _detected;

  @override
  Future<void> start() async {
    _detected = false;
  }

  @override
  Future<void> stop() async {
    _lostTimer?.cancel();
  }

  @override
  void notifyInteraction() {
    _lostTimer?.cancel();
    if (!_detected) {
      _detected = true;
      _controller.add(PresenceStatus.presenceDetected);
    }
    // Schedule presence lost after 20 seconds of no interaction
    _lostTimer = Timer(const Duration(seconds: 20), () {
      _detected = false;
      _controller.add(PresenceStatus.presenceLost);
    });
  }

  @override
  void dispose() {
    _lostTimer?.cancel();
    _controller.close();
  }
}

/// Pluggable Camera Vision / TFLite detector interface
/// Operates on-device in-memory only (2-4 fps, downscaled frame, no images stored)
class CameraVisionPresenceDetector implements PresenceDetector {
  final _controller = StreamController<PresenceStatus>.broadcast();
  bool _detected = false;
  int _consecutiveDetections = 0;

  @override
  Stream<PresenceStatus> get presenceStream => _controller.stream;

  @override
  bool get isPresenceDetected => _detected;

  @override
  Future<void> start() async {
    // In-memory person bounding box detector initialization
  }

  @override
  Future<void> stop() async {}

  @override
  void notifyInteraction() {
    if (!_detected) {
      _detected = true;
      _controller.add(PresenceStatus.presenceDetected);
    }
  }

  /// Process downscaled frame in memory (discarded immediately after evaluation)
  void processFrameInMemory({required bool personDetected, required double boundingBoxAreaRatio}) {
    if (personDetected && boundingBoxAreaRatio >= 0.15) {
      _consecutiveDetections++;
      if (_consecutiveDetections >= 3 && !_detected) {
        _detected = true;
        _controller.add(PresenceStatus.presenceDetected);
      }
    } else {
      _consecutiveDetections = 0;
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}
