enum DisguiseType { calculator, lowBattery, blackScreen }

class UserSettings {
  bool shakeTriggerEnabled;
  bool volumeKeyTriggerEnabled;
  bool autoCallEnabled;
  int autoCallDelaySeconds;
  DisguiseType preferredDisguise;
  String policeEmergencyNumber;
  int locationUpdateIntervalSeconds;
  int videoChunkDurationSeconds;
  bool encryptEvidence;
  bool isPremiumUser;
  String subscriptionType;
  String? subscriptionExpiry;
  int registeredUserCount;

  UserSettings({
    this.shakeTriggerEnabled = true,
    this.volumeKeyTriggerEnabled = true,
    this.autoCallEnabled = true,
    this.autoCallDelaySeconds = 10,
    this.preferredDisguise = DisguiseType.calculator,
    this.policeEmergencyNumber = '112',
    this.locationUpdateIntervalSeconds = 30,
    this.videoChunkDurationSeconds = 30,
    this.encryptEvidence = true,
    this.isPremiumUser = false,
    this.subscriptionType = 'free',
    this.subscriptionExpiry,
    this.registeredUserCount = 1240,
  });

  Map<String, dynamic> toMap() {
    return {
      'shakeTriggerEnabled': shakeTriggerEnabled,
      'volumeKeyTriggerEnabled': volumeKeyTriggerEnabled,
      'autoCallEnabled': autoCallEnabled,
      'autoCallDelaySeconds': autoCallDelaySeconds,
      'preferredDisguise': preferredDisguise.name,
      'policeEmergencyNumber': policeEmergencyNumber,
      'locationUpdateIntervalSeconds': locationUpdateIntervalSeconds,
      'videoChunkDurationSeconds': videoChunkDurationSeconds,
      'encryptEvidence': encryptEvidence,
      'isPremiumUser': isPremiumUser,
      'subscriptionType': subscriptionType,
      'subscriptionExpiry': subscriptionExpiry,
      'registeredUserCount': registeredUserCount,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      shakeTriggerEnabled: map['shakeTriggerEnabled'] ?? true,
      volumeKeyTriggerEnabled: map['volumeKeyTriggerEnabled'] ?? true,
      autoCallEnabled: map['autoCallEnabled'] ?? true,
      autoCallDelaySeconds: map['autoCallDelaySeconds'] ?? 10,
      preferredDisguise: DisguiseType.values.firstWhere(
        (e) => e.name == map['preferredDisguise'],
        orElse: () => DisguiseType.calculator,
      ),
      policeEmergencyNumber: map['policeEmergencyNumber'] ?? '112',
      locationUpdateIntervalSeconds: map['locationUpdateIntervalSeconds'] ?? 30,
      videoChunkDurationSeconds: map['videoChunkDurationSeconds'] ?? 30,
      encryptEvidence: map['encryptEvidence'] ?? true,
      isPremiumUser: map['isPremiumUser'] ?? false,
      subscriptionType: map['subscriptionType'] ?? 'free',
      subscriptionExpiry: map['subscriptionExpiry'],
      registeredUserCount: map['registeredUserCount'] ?? 1240,
    );
  }
}
