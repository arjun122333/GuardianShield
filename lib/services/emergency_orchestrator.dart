import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/emergency_contact.dart';
import '../data/models/emergency_session.dart';
import '../data/models/location_payload.dart';
import '../data/models/user_settings.dart';
import '../data/repositories/mock_firestore_repository.dart';
import '../core/security/pin_vault_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location_tracker_service.dart';
import 'shake_detection_service.dart';
import 'sms_alert_service.dart';
import 'hidden_camera_service.dart';

class EmergencyOrchestrator extends ChangeNotifier {
  final LocationTrackerService _locationService = LocationTrackerService();
  final ShakeDetectionService _shakeService = ShakeDetectionService();
  final HiddenCameraService _cameraService = HiddenCameraService();

  SosStatus _currentStatus = SosStatus.cancelled;
  EmergencySession? _currentSession;
  UserSettings _settings = UserSettings();
  List<EmergencyContact> _contacts = [];
  LocationPayload? _currentLocation;
  Timer? _autoCallTimer;
  Timer? _continuousAlertTimer;

  SosStatus get currentStatus => _currentStatus;
  EmergencySession? get currentSession => _currentSession;
  UserSettings get settings => _settings;
  List<EmergencyContact> get contacts => _contacts;
  LocationPayload? get currentLocation => _currentLocation;
  bool get isSosActive => _currentStatus == SosStatus.active || _currentStatus == SosStatus.decoyActive || _currentStatus == SosStatus.stealth;
  HiddenCameraService get cameraService => _cameraService;

  EmergencyOrchestrator() {
    _init();
  }

  Future<void> _init() async {
    _settings = await SafeStorageRepository.getUserSettings();
    _contacts = await SafeStorageRepository.getContacts();
    _currentStatus = SosStatus.resolved;

    // Start shake listener if enabled
    if (_settings.shakeTriggerEnabled) {
      _shakeService.startListening(
        onTripleShakeDetected: () {
          triggerEmergency(SosTriggerType.shake3x);
        },
      );
    }

    // Subscribe to location updates
    _locationService.locationStream.listen((location) {
      _currentLocation = location;
      if (isSosActive && _currentSession != null) {
        _currentSession!.locationBreadcrumbs.add(location);
      }
      notifyListeners();
    });

    // Fetch initial location fix
    fetchCurrentLocation();

    notifyListeners();
  }

  /// Fetches and updates current GPS location
  Future<LocationPayload?> fetchCurrentLocation() async {
    final loc = await _locationService.getCurrentLocation();
    if (loc != null) {
      _currentLocation = loc;
      notifyListeners();
    }
    return loc;
  }

  /// Triggers full Emergency SOS Sequence
  Future<void> triggerEmergency(SosTriggerType triggerType) async {
    if (isSosActive) return;

    // Critical: Request all required hardware permissions before proceeding
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.sms,
      Permission.phone,
      Permission.camera,
      Permission.microphone,
    ].request();

    // Log permission status but proceed with whatever we have (best effort)
    debugPrint('SOS Permissions Status: $statuses');

    _currentStatus = SosStatus.active;
    _currentSession = EmergencySession(
      id: const Uuid().v4(),
      startTime: DateTime.now(),
      triggerType: triggerType,
      status: SosStatus.active,
    );
    notifyListeners();

    // 1. Immediately capture GPS location
    _currentLocation = await _locationService.getCurrentLocation();
    if (_currentLocation != null) {
      _currentSession!.locationBreadcrumbs.add(_currentLocation!);
    }

    // 2. Start continuous GPS stream
    _locationService.startTracking(
      intervalSeconds: _settings.locationUpdateIntervalSeconds,
    );

    // 3. Dispatch SMS Alerts with Google Maps link (Immediate & Direct)
    final message = SmsAlertService.formatEmergencyMessage(
      userName: 'Guardian Shield User',
      location: _currentLocation,
    );
    
    debugPrint('Broadcasting IMMEDIATE emergency SMS to ${_contacts.length} guardians...');
    await SmsAlertService.broadcastEmergencySms(
      contacts: _contacts,
      message: message,
    );

    // 4. Trigger Direct Phone Call to primary guardian (Direct Call without user intervention)
    if (_settings.autoCallEnabled && _contacts.isNotEmpty) {
      final primaryContact = _contacts.firstWhere(
        (c) => c.isPrimary && c.receiveAutoCall,
        orElse: () => _contacts.first,
      );

      debugPrint('Initiating direct call to ${primaryContact.name} in ${_settings.autoCallDelaySeconds}s...');
      _autoCallTimer?.cancel();
      _autoCallTimer = Timer(Duration(seconds: _settings.autoCallDelaySeconds > 0 ? _settings.autoCallDelaySeconds : 1), () {
        if (isSosActive) {
          SmsAlertService.launchEmergencyCall(primaryContact.phoneNumber);
        }
      });
    }

    // 5. Start hidden camera recording silently
    debugPrint('Starting hidden background camera recording...');
    await _cameraService.startHiddenRecording(
      segmentDurationSeconds: _settings.videoChunkDurationSeconds,
      onSegmentCompleted: (videoPath) {
        if (_currentSession != null && !_currentSession!.evidenceChunkUrls.contains(videoPath)) {
          _currentSession!.evidenceChunkUrls.add(videoPath);
          debugPrint('Added recorded video chunk to session: $videoPath');
        }
      },
    );

    // 6. Schedule continuous repeat SMS alerts every 2 minutes for "Live" tracking
    _continuousAlertTimer?.cancel();
    _continuousAlertTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!isSosActive) {
        timer.cancel();
        return;
      }
      final updateMsg = SmsAlertService.formatEmergencyMessage(
        userName: 'Guardian Shield User (LIVE)',
        location: _currentLocation,
      );
      SmsAlertService.broadcastEmergencySms(
        contacts: _contacts,
        message: updateMsg,
      );
    });

    notifyListeners();
  }

  /// Switches app display into Decoy Disguise Mode (e.g. Fake Calculator)
  void enterDecoyMode() {
    if (isSosActive) {
      _currentStatus = SosStatus.decoyActive;
      notifyListeners();
    }
  }

  /// Cancels / Resolves Emergency SOS (Requires correct Master Safe PIN)
  Future<bool> resolveEmergency(String pin) async {
    // 1. Handle Duress PIN (Stealth Continuation)
    if (PinVaultService.isDuressPin(pin)) {
      debugPrint('DURESS PIN DETECTED! Entering stealth mode...');
      
      // Update status to stealth (keeps recording/tracking alive, but hides banner)
      _currentStatus = SosStatus.stealth;
      notifyListeners();

      // Send immediate "Duress" alert to guardians
      const duressMsg = '⚠️ ALERT! User entered DURESS PIN in Guardian Shield. This is a forced stand-down. SILENT TRACKING REMAINS ACTIVE.';
      SmsAlertService.broadcastEmergencySms(contacts: _contacts, message: duressMsg);
      
      return true; // Return true so the dialog closes and the user appears safe
    }

    // 2. Handle Master PIN (Actual Resolution)
    final isValid = await PinVaultService.verifyMasterPin(pin);
    if (!isValid) return false;

    _autoCallTimer?.cancel();
    _continuousAlertTimer?.cancel();
    _locationService.stopTracking();
    
    // Capture the final recorded paths (including the last segment)
    final allPaths = await _cameraService.stopHiddenRecording();

    if (_currentSession != null) {
      _currentSession!.endTime = DateTime.now();
      _currentSession!.status = SosStatus.resolved;
      
      // Ensure all recorded paths are in the session (avoid duplicates)
      for (var path in allPaths) {
        if (!_currentSession!.evidenceChunkUrls.contains(path)) {
          _currentSession!.evidenceChunkUrls.add(path);
        }
      }
      
      await SafeStorageRepository.recordSession(_currentSession!);
    }

    _currentStatus = SosStatus.resolved;
    notifyListeners();
    return true;
  }

  Future<void> reloadSettings() async {
    _settings = await SafeStorageRepository.getUserSettings();
    _contacts = await SafeStorageRepository.getContacts();
    notifyListeners();
  }

  @override
  void dispose() {
    _autoCallTimer?.cancel();
    _continuousAlertTimer?.cancel();
    _shakeService.stopListening();
    _locationService.dispose();
    _cameraService.dispose();
    super.dispose();
  }
}
