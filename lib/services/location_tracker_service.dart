import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/location_payload.dart';

class LocationTrackerService {
  StreamSubscription<Position>? _positionStreamSubscription;
  LocationPayload? _lastKnownLocation;
  
  final _locationController = StreamController<LocationPayload>.broadcast();
  Stream<LocationPayload> get locationStream => _locationController.stream;
  LocationPayload? get lastKnownLocation => _lastKnownLocation;

  /// Fetches current immediate location with fallback to last known position
  Future<LocationPayload?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location service disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          debugPrint('Location permission denied.');
          return null;
        }
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (e) {
        debugPrint('High accuracy position timeout/error: $e. Requesting last known position.');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        _lastKnownLocation = LocationPayload(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed,
          altitude: position.altitude,
          timestamp: position.timestamp,
        );
        _locationController.add(_lastKnownLocation!);
      }

      return _lastKnownLocation;
    } catch (e) {
      debugPrint('Error getting location payload: $e');
      return _lastKnownLocation;
    }
  }

  /// Starts continuous background location updates
  void startTracking({int intervalSeconds = 15}) {
    stopTracking();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final payload = LocationPayload(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        altitude: position.altitude,
        timestamp: position.timestamp,
      );

      _lastKnownLocation = payload;
      _locationController.add(payload);
    }, onError: (e) {
      debugPrint('Location stream error: $e');
    });
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
