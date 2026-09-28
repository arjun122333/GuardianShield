import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  /// Checks whether all critical permissions are granted
  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    final permissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.camera,
      Permission.microphone,
      Permission.sms,
      Permission.phone,
    ];

    Map<Permission, PermissionStatus> statuses = {};
    for (var p in permissions) {
      statuses[p] = await p.status;
    }
    return statuses;
  }

  /// Requests critical emergency permissions in sequence with rationale
  static Future<bool> requestEmergencyPermissions() async {
    // 1. Foreground Location
    final locStatus = await Permission.location.request();
    if (locStatus.isGranted) {
      // 2. Background Location
      await Permission.locationAlways.request();
    }

    // 3. Camera, Microphone, SMS, Phone & Media Storage permissions
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.sms,
      Permission.phone,
      Permission.videos,
      Permission.photos,
      Permission.storage,
    ].request();

    debugPrint('Permission Statuses: $statuses');

    // Recheck critical baseline (Location & SMS)
    final isLocationOk = await Permission.location.isGranted;
    final isSmsOk = await Permission.sms.isGranted;
    
    return isLocationOk && isSmsOk;
  }
}
