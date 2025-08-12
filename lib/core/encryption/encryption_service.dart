import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  Encrypter? _encrypter;
  IV? _iv;
  bool _isInitialized = false;
  String? _currentMasterPassword;

  /// Initialize the encryption service with a master password for record encryption
  Future<void> initializeWithMasterPassword(String masterPassword) async {
    try {
      // Generate a consistent salt from master password
      final salt = _generateDeterministicSalt(masterPassword);
      final key = await _deriveKey(masterPassword, salt);
      
      _iv = IV.fromSecureRandom(16);
      _encrypter = Encrypter(AES(Key.fromBase64(base64.encode(key))));
      _currentMasterPassword = masterPassword;
      _isInitialized = true;
      
      print('Encryption service initialized successfully');
    } catch (e) {
      print('Failed to initialize encryption service: $e');
      throw Exception('Failed to initialize encryption service: $e');
    }
  }

  /// Reset the encryption service (useful for changing master password)
  void reset() {
    _iv = null;
    _encrypter = null;
    _currentMasterPassword = null;
    _isInitialized = false;
    print('Encryption service reset');
  }

  /// Check if the service is properly initialized
  bool get isInitialized => _isInitialized;

  /// Generate a deterministic salt from master password for consistency
  Uint8List _generateDeterministicSalt(String masterPassword) {
    final bytes = utf8.encode('tiny_password_salt_v1_$masterPassword');
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes.take(32).toList());
  }

  /// Generate a truly random salt for database passwords
  Uint8List _generateRandomSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (i) => random.nextInt(256)),
    );
  }

  /// Derive an encryption key from password using PBKDF2
  Future<Uint8List> _deriveKey(String password, Uint8List salt) async {
    final codec = utf8.encoder;
    final passwordBytes = codec.convert(password);
    final hmac = Hmac(sha256, passwordBytes);
    final bytes = await _pbkdf2(
      hmac: hmac,
      salt: salt,
      iterations: 100000,
      length: 32,
    );
    return bytes;
  }

  /// PBKDF2 key derivation function
  Future<Uint8List> _pbkdf2({
    required Hmac hmac,
    required Uint8List salt,
    required int iterations,
    required int length,
  }) async {
    final blocks = (length / 32).ceil();
    final Uint8List result = Uint8List(length);
    int offset = 0;

    for (var i = 1; i <= blocks; i++) {
      final block = await _pbkdf2Block(hmac, salt, iterations, i);
      result.setRange(
        offset,
        offset + block.length > length ? length : offset + block.length,
        block,
      );
      offset += 32;
    }

    return result;
  }

  /// Generate a single block for PBKDF2
  Future<Uint8List> _pbkdf2Block(
    Hmac hmac,
    Uint8List salt,
    int iterations,
    int blockNumber,
  ) async {
    final block = Uint8List(salt.length + 4);
    block.setRange(0, salt.length, salt);
    block.buffer.asByteData().setInt32(salt.length, blockNumber);

    var result = hmac.convert(block).bytes;
    var previous = result;

    for (var i = 1; i < iterations; i++) {
      previous = hmac.convert(previous).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= previous[j];
      }
    }

    return Uint8List.fromList(result);
  }

  /// Encrypt data (for record fields)
  String encrypt(String data) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw Exception('EncryptionService not initialized. Call initializeWithMasterPassword() first.');
    }
    try {
      final encrypted = _encrypter!.encrypt(data, iv: _iv!);
      return encrypted.base64;
    } catch (e) {
      print('Encryption failed: $e');
      throw Exception('Failed to encrypt data: $e');
    }
  }

  /// Decrypt data (for record fields)
  String decrypt(String encryptedData) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw Exception('EncryptionService not initialized. Call initializeWithMasterPassword() first.');
    }
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter!.decrypt(encrypted, iv: _iv!);
    } catch (e) {
      print('Decryption failed: $e');
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Generate a secure random password (independent of encryption state)
  String generatePassword({
    required int length,
    required bool useUppercase,
    required bool useLowercase,
    required bool useNumbers,
    required bool useSpecial,
    required bool excludeSimilar,
  }) {
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const special = r'!@#$%^&*()_+-=[]{}|;:,.<>?';
    const similar = 'iIlL1oO0';

    String chars = '';
    if (useLowercase) chars += lowercase;
    if (useUppercase) chars += uppercase;
    if (useNumbers) chars += numbers;
    if (useSpecial) chars += special;
    if (excludeSimilar) {
      for (var c in similar.split('')) {
        chars = chars.replaceAll(c, '');
      }
    }

    if (chars.isEmpty) {
      throw ArgumentError('At least one character set must be selected');
    }

    final random = Random.secure();
    final buffer = StringBuffer();

    for (var i = 0; i < length; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }

    return buffer.toString();
  }

  /// Generate a secure database password (separate from master password)
  String generateDatabasePassword() {
    return generatePassword(
      length: 64,
      useUppercase: true,
      useLowercase: true,
      useNumbers: true,
      useSpecial: true,
      excludeSimilar: true,
    );
  }

  /// Hash a password for storage (independent of encryption state)
  String hashPassword(String password) {
    try {
      final bytes = utf8.encode(password);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      print('Password hashing failed: $e');
      throw Exception('Failed to hash password: $e');
    }
  }

  /// Verify a password against its hash (independent of encryption state)
  bool verifyPassword(String password, String hash) {
    try {
      final hashedPassword = hashPassword(password);
      return hashedPassword == hash;
    } catch (e) {
      print('Password verification failed: $e');
      return false;
    }
  }

  /// Get current master password (for debugging/testing only)
  String? get currentMasterPassword => _currentMasterPassword;
}