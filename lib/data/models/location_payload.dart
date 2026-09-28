class LocationPayload {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final double? altitude;
  final DateTime timestamp;

  LocationPayload({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    this.altitude,
    required this.timestamp,
  });

  String get googleMapsUrl => 
      'https://maps.google.com/?q=$latitude,$longitude';

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
      'mapsUrl': googleMapsUrl,
    };
  }

  factory LocationPayload.fromMap(Map<String, dynamic> map) {
    return LocationPayload(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      speed: map['speed'] != null ? (map['speed'] as num).toDouble() : null,
      altitude: map['altitude'] != null ? (map['altitude'] as num).toDouble() : null,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
