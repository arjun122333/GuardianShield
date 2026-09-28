import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../data/models/emergency_contact.dart';
import '../data/models/location_payload.dart';

class SmsAlertService {
  static const MethodChannel _smsChannel = MethodChannel('com.guardianshield.app/sms');
  static final Telephony telephony = Telephony.instance;

  /// Formats the official SOS emergency dispatch message with WhatsApp / Google Maps live link
  static String formatEmergencyMessage({
    required String userName,
    LocationPayload? location,
  }) {
    final now = DateTime.now();
    final timeStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    
    final mapsLink = location != null
        ? "https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}"
        : 'Location unavailable (acquiring GPS...)';

    final accuracyInfo = location != null ? "\n🎯 Accuracy: ±${location.accuracy.toStringAsFixed(1)}m" : "";

    return '🚨 LIVE EMERGENCY SOS ALERT from $userName!\n'
        'I am in danger and require immediate assistance.\n'
        '📍 Live GPS Location Stream:\n$mapsLink$accuracyInfo\n'
        '⏰ Time: $timeStr\n'
        '- Sent silently via Guardian Shield Live Tracker';
  }

  /// Sends emergency SMS to all configured guardians silently in background without user interference
  static Future<bool> broadcastEmergencySms({
    required List<EmergencyContact> contacts,
    required String message,
  }) async {
    if (contacts.isEmpty) {
      debugPrint('No emergency contacts configured. SMS broadcast skipped.');
      return false;
    }

    bool allSuccess = true;
    for (var contact in contacts) {
      try {
        final cleanPhone = contact.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
        debugPrint('Attempting Direct Native MethodChannel SMS to ${contact.name} at $cleanPhone');
        
        final bool? success = await _smsChannel.invokeMethod('sendDirectSms', {
          'phone': cleanPhone,
          'message': message,
        });

        if (success == true) {
          debugPrint('✅ Direct native SMS sent silently to ${contact.name}');
          continue;
        }
      } catch (e) {
        debugPrint('Direct native MethodChannel SMS failed for ${contact.name}: $e. Trying telephony fallback...');
      }

      // Fallback: Telephony plugin
      try {
        final cleanPhone = contact.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
        await telephony.sendSms(
          to: cleanPhone,
          message: message,
        );
        debugPrint('Telephony background SMS dispatched for ${contact.name}');
      } catch (telephonyError) {
        debugPrint('Telephony background SMS failed for ${contact.name}: $telephonyError');
        allSuccess = false;
      }
    }
    return allSuccess;
  }

  /// Triggers an immediate direct phone call to primary guardian without user interference
  static Future<bool> launchEmergencyCall(String phoneNumber) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      debugPrint('Attempting Direct Call to $cleanPhone');
      
      // Try direct calling (No user interference)
      final bool? res = await FlutterPhoneDirectCaller.callNumber(cleanPhone);
      
      if (res == true) {
        debugPrint('Direct call initiated successfully');
        return true;
      } else {
        debugPrint('Direct call failed. Falling back to Dialer.');
        // Fallback to dialer
        final telUri = Uri.parse('tel:$cleanPhone');
        if (await canLaunchUrl(telUri)) {
          return await launchUrl(telUri, mode: LaunchMode.externalApplication);
        }
      }
      return false;
    } catch (e) {
      debugPrint('Direct Call error: $e');
      return false;
    }
  }
}
