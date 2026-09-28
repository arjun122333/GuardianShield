import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_contact.dart';
import '../models/emergency_session.dart';
import '../models/user_settings.dart';

class SafeStorageRepository {
  static const String _kContactsKey = 'gs_contacts_list';
  static const String _kSettingsKey = 'gs_user_settings';
  static const String _kSessionsKey = 'gs_emergency_sessions';

  // --- Emergency Contacts Management ---
  static Future<List<EmergencyContact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kContactsKey);
    if (jsonStr == null) {
      // Default sample emergency services
      return [
        EmergencyContact(
          id: const Uuid().v4(),
          name: 'Primary Guardian (Mom)',
          phoneNumber: '+1234567890',
          relationship: 'Parent',
          isPrimary: true,
          receiveAutoCall: true,
        ),
        EmergencyContact(
          id: const Uuid().v4(),
          name: 'Local Emergency Helpline',
          phoneNumber: '112',
          relationship: 'Emergency Services',
          isPrimary: false,
          receiveAutoCall: false,
        ),
      ];
    }
    final List list = jsonDecode(jsonStr);
    return list.map((e) => EmergencyContact.fromMap(e)).toList();
  }

  static Future<void> saveContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final list = contacts.map((c) => c.toMap()).toList();
    await prefs.setString(_kContactsKey, jsonEncode(list));
  }

  static Future<void> addContact(EmergencyContact contact) async {
    final list = await getContacts();
    if (list.length >= 5) {
      throw Exception('Maximum 5 emergency contacts allowed.');
    }
    list.add(contact);
    await saveContacts(list);
  }

  static Future<void> deleteContact(String contactId) async {
    final list = await getContacts();
    list.removeWhere((c) => c.id == contactId);
    await saveContacts(list);
  }

  // --- User Settings Management ---
  static Future<UserSettings> getUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kSettingsKey);
    if (jsonStr == null) return UserSettings();
    return UserSettings.fromMap(jsonDecode(jsonStr));
  }

  static Future<void> saveUserSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettingsKey, jsonEncode(settings.toMap()));
  }

  // --- Incident Sessions & Evidence Vault ---
  static Future<List<EmergencySession>> getPastSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kSessionsKey);
    if (jsonStr == null) return [];
    final List list = jsonDecode(jsonStr);
    return list.map((s) => EmergencySession.fromMap(s)).toList();
  }

  static Future<void> recordSession(EmergencySession session) async {
    final list = await getPastSessions();
    list.insert(0, session); // Newest first
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionsKey, jsonEncode(list.map((s) => s.toMap()).toList()));
  }
}
