import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  /// Derives a 256-bit AES key from the user's PIN + device Salt
  static enc.Key deriveKeyFromPin(String pin, {String salt = 'guardian_shield_salt_2026'}) {
    final bytes = utf8.encode('$pin:$salt');
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts text payload (such as location logs or metadata)
  static String encryptPayload(String plainText, enc.Key key) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Store IV along with ciphertext (base64 encoded)
    final combined = {
      'iv': iv.base64,
      'data': encrypted.base64,
    };
    return jsonEncode(combined);
  }

  /// Decrypts payload using the user's key
  static String decryptPayload(String cipherJson, enc.Key key) {
    try {
      final Map<String, dynamic> map = jsonDecode(cipherJson);
      final iv = enc.IV.fromBase64(map['iv']);
      final encryptedData = enc.Encrypted.fromBase64(map['data']);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      return '[Decryption Failed: Invalid Key]';
    }
  }
}
