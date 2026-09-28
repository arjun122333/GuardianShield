import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PinVaultService {
  static const String _kMasterPinHashKey = 'gs_master_pin_hash';
  static const String _kDecoyPinKey = 'gs_decoy_pin';
  static const String _kIsConfiguredKey = 'gs_vault_configured';

  static String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  /// Sets up user PINs on initial configuration
  static Future<void> setupPins({
    required String masterPin,
    required String decoyPin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMasterPinHashKey, _hashPin(masterPin));
    await prefs.setString(_kDecoyPinKey, decoyPin);
    await prefs.setBool(_kIsConfiguredKey, true);
  }

  /// Verifies if master PIN is correct to exit SOS or access vault
  static Future<bool> verifyMasterPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_kMasterPinHashKey);
    if (storedHash == null) {
      // Default initial PIN: 1234
      return enteredPin == '1234';
    }
    return storedHash == _hashPin(enteredPin);
  }

  /// Gets the decoy PIN (used to unlock calculator disguise)
  static Future<String> getDecoyPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDecoyPinKey) ?? '9119';
  }

  static Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsConfiguredKey) ?? false;
  }

  /// Checks if the entered PIN is the hardcoded Duress PIN (4321)
  /// In a real app, this would be user-configurable.
  static bool isDuressPin(String pin) {
    return pin == '4321';
  }
}
