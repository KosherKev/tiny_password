import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class CryptoUtils {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits
  static const int _iterations = 100000;

  Key? _key;
  IV? _iv;
  Encrypter? _encrypter;
  bool _isInitialized = false;

  Future<void> initialize(String masterPassword) async {
    final salt = _generateSalt();
    final keyMaterial = await _deriveKey(masterPassword, salt);
    
    _key = Key(keyMaterial.sublist(0, _keyLength));
    _iv = IV(keyMaterial.sublist(_keyLength, _keyLength + _ivLength));
    _encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));
    _isInitialized = true;
  }

  Uint8List _generateSalt() {
    // Use a consistent salt for now - in production you'd want to store this securely
    return Uint8List.fromList(utf8.encode('tiny_password_salt_v1'));
  }

  Future<Uint8List> _deriveKey(String password, Uint8List salt) async {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, salt);
    
    var derived = Uint8List.fromList(passwordBytes + salt);
    
    for (var i = 0; i < _iterations; i++) {
      derived = Uint8List.fromList(hmac.convert(derived).bytes);
    }
    
    // Ensure we have enough bytes for key + IV
    while (derived.length < _keyLength + _ivLength) {
      derived = Uint8List.fromList(derived + hmac.convert(derived).bytes);
    }
    
    return derived.sublist(0, _keyLength + _ivLength);
  }

  Future<String> hashPassword(String password) async {
    final salt = _generateSalt();
    final keyBytes = await _deriveKey(password, salt);
    return base64.encode(keyBytes);
  }

  String encrypt(String plainText) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw Exception('CryptoUtils not initialized');
    }
    return _encrypter!.encrypt(plainText, iv: _iv!).base64;
  }

  String decrypt(String encrypted) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw Exception('CryptoUtils not initialized');
    }
    return _encrypter!.decrypt64(encrypted, iv: _iv!);
  }

  Future<bool> verifyPassword(String password, String hashedPassword) async {
    final hash = await hashPassword(password);
    return hash == hashedPassword;
  }

  String generateSecurePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
  }) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    String chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSpecialChars) chars += special;
    
    if (chars.isEmpty) {
      throw ArgumentError('At least one character set must be included');
    }
    
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length, 
        (_) => chars.codeUnitAt(random.nextInt(chars.length))
      )
    );
  }
}