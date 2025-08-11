import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class CryptoUtils {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits
  static const int _iterations = 100000;

  late final Key _key;
  late final IV _iv;
  late final Encrypter _encrypter;

  Future<void> initialize(String masterPassword) async {
    final salt = Uint8List.fromList(utf8.encode('tiny_password_salt'));
    final keyBytes = await _deriveKey(masterPassword, salt);
    
    _key = Key(keyBytes.sublist(0, _keyLength));
    _iv = IV(keyBytes.sublist(_keyLength, _keyLength + _ivLength));
    _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
  }

  Future<Uint8List> _deriveKey(String password, Uint8List salt) async {
    final bytes = utf8.encode(password);
    var key = Uint8List.fromList(bytes);

    for (var i = 0; i < _iterations; i++) {
      final hmac = Hmac(sha256, salt);
      key = await hmac.convert(key).bytes as Uint8List;
    }

    return key;
  }

  Future<String> hashPassword(String password) async {
    final salt = Uint8List.fromList(utf8.encode('tiny_password_salt'));
    final keyBytes = await _deriveKey(password, salt);
    return base64.encode(keyBytes);
  }

  String encrypt(String plainText) {
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  String decrypt(String encrypted) {
    return _encrypter.decrypt64(encrypted, iv: _iv);
  }

  Future<bool> verifyPassword(String password, String hashedPassword) async {
    final hash = await hashPassword(password);
    return hash == hashedPassword;
  }
}