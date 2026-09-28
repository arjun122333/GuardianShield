import 'location_payload.dart';

enum SosTriggerType { panicButton, shake3x, volumeKey, powerKey }
enum SosStatus { active, decoyActive, resolved, cancelled, stealth }

class EmergencySession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final SosTriggerType triggerType;
  SosStatus status;
  final List<LocationPayload> locationBreadcrumbs;
  final List<String> evidenceChunkUrls;
  final bool smsDispatched;
  final bool policeNotified;

  EmergencySession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.triggerType,
    this.status = SosStatus.active,
    List<LocationPayload>? locationBreadcrumbs,
    List<String>? evidenceChunkUrls,
    this.smsDispatched = false,
    this.policeNotified = false,
  })  : locationBreadcrumbs = locationBreadcrumbs ?? [],
        evidenceChunkUrls = evidenceChunkUrls ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'triggerType': triggerType.name,
      'status': status.name,
      'locationBreadcrumbs': locationBreadcrumbs.map((l) => l.toMap()).toList(),
      'evidenceChunkUrls': evidenceChunkUrls,
      'smsDispatched': smsDispatched,
      'policeNotified': policeNotified,
    };
  }

  factory EmergencySession.fromMap(Map<String, dynamic> map) {
    return EmergencySession(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      triggerType: SosTriggerType.values.firstWhere(
        (e) => e.name == map['triggerType'],
        orElse: () => SosTriggerType.panicButton,
      ),
      status: SosStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SosStatus.active,
      ),
      locationBreadcrumbs: (map['locationBreadcrumbs'] as List? ?? [])
          .map((i) => LocationPayload.fromMap(i))
          .toList(),
      evidenceChunkUrls: List<String>.from(map['evidenceChunkUrls'] ?? []),
      smsDispatched: map['smsDispatched'] ?? false,
      policeNotified: map['policeNotified'] ?? false,
    );
  }
}
