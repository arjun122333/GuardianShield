import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetectionService {
  StreamSubscription? _accelerometerSubscription;
  int _shakeCount = 0;
  DateTime? _lastShakeTimestamp;
  
  // Shake configuration constants
  final double _shakeThresholdGravity = 2.4; // ~23.5 m/s²
  final int _resetWindowMs = 2000;           // Window to complete 3 shakes
  final int _shakeDebounceMs = 250;          // Ignore sensor noise within 250ms

  bool _isListening = false;
  bool get isListening => _isListening;

  void startListening({required VoidCallback onTripleShakeDetected}) {
    if (_isListening) return;
    _isListening = true;
    _shakeCount = 0;
    _lastShakeTimestamp = null;

    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Calculate G-force magnitude: sqrt(x² + y² + z²) / 9.81
        double gX = event.x / 9.80665;
        double gY = event.y / 9.80665;
        double gZ = event.z / 9.80665;
        double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

        if (gForce > _shakeThresholdGravity) {
          final now = DateTime.now();

          // If last shake was too long ago, reset counter
          if (_lastShakeTimestamp == null ||
              now.difference(_lastShakeTimestamp!).inMilliseconds > _resetWindowMs) {
            _shakeCount = 1;
            _lastShakeTimestamp = now;
          } else if (now.difference(_lastShakeTimestamp!).inMilliseconds > _shakeDebounceMs) {
            _shakeCount++;
            _lastShakeTimestamp = now;

            if (_shakeCount >= 3) {
              _shakeCount = 0;
              _lastShakeTimestamp = null;
              onTripleShakeDetected();
            }
          }
        }
      },
      onError: (e) {
        debugPrint('Shake sensor error: $e');
      },
      cancelOnError: false,
    );
  }

  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isListening = false;
    _shakeCount = 0;
  }
}
