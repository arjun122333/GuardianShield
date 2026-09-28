class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;
  final bool receiveAutoCall;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.relationship = 'Guardian',
    this.isPrimary = false,
    this.receiveAutoCall = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'receiveAutoCall': receiveAutoCall,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'] ?? 'Guardian',
      isPrimary: map['isPrimary'] ?? false,
      receiveAutoCall: map['receiveAutoCall'] ?? true,
    );
  }
}
