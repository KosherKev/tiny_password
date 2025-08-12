import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  FlutterSecureStorage? _storage;
  SharedPreferences? _prefs;
  bool _useSecureStorage = true;

  static const _keyDatabasePassword = 'database_password';
  static const _keyMasterPassword = 'master_password_hash';
  static const _keyEncryptionKey = 'encryption_key';
  static const _keyIV = 'encryption_iv';

  Future<void> _initStorage() async {
    try {
      _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
      
      // Test if secure storage works
      await _storage!.write(key: 'test_key', value: 'test_value');
      await _storage!.delete(key: 'test_key');
    } catch (e) {
      print('Secure storage not available, falling back to SharedPreferences: $e');
      _useSecureStorage = false;
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<void> _write(String key, String value) async {
    if (_storage == null && _prefs == null) {
      await _initStorage();
    }

    if (_useSecureStorage && _storage != null) {
      try {
        await _storage!.write(key: key, value: value);
        return;
      } catch (e) {
        print('Secure storage write failed, falling back: $e');
        _useSecureStorage = false;
        _prefs ??= await SharedPreferences.getInstance();
      }
    }

    // Fallback to SharedPreferences with basic encoding
    if (_prefs != null) {
      final encoded = base64.encode(utf8.encode(value));
      await _prefs!.setString(key, encoded);
    }
  }

  Future<String?> _read(String key) async {
    if (_storage == null && _prefs == null) {
      await _initStorage();
    }

    if (_useSecureStorage && _storage != null) {
      try {
        return await _storage!.read(key: key);
      } catch (e) {
        print('Secure storage read failed, falling back: $e');
        _useSecureStorage = false;
        _prefs ??= await SharedPreferences.getInstance();
      }
    }

    // Fallback to SharedPreferences
    if (_prefs != null) {
      final encoded = _prefs!.getString(key);
      if (encoded != null) {
        try {
          return utf8.decode(base64.decode(encoded));
        } catch (e) {
          print('Failed to decode stored value: $e');
          return null;
        }
      }
    }

    return null;
  }

  Future<void> storeDatabasePassword(String password) async {
    await _write(_keyDatabasePassword, password);
  }

  Future<String?> getDatabasePassword() async {
    return await _read(_keyDatabasePassword);
  }

  Future<void> storeMasterPasswordHash(String hash) async {
    await _write(_keyMasterPassword, hash);
  }

  Future<String?> getMasterPasswordHash() async {
    return await _read(_keyMasterPassword);
  }

  Future<void> storeEncryptionKey(String key) async {
    await _write(_keyEncryptionKey, key);
  }

  Future<String?> getEncryptionKey() async {
    return await _read(_keyEncryptionKey);
  }

  Future<void> storeIV(String iv) async {
    await _write(_keyIV, iv);
  }

  Future<String?> getIV() async {
    return await _read(_keyIV);
  }

  Future<void> deleteAll() async {
    if (_useSecureStorage && _storage != null) {
      try {
        await _storage!.deleteAll();
        return;
      } catch (e) {
        print('Secure storage deleteAll failed, falling back: $e');
        _useSecureStorage = false;
        _prefs ??= await SharedPreferences.getInstance();
      }
    }

    if (_prefs != null) {
      final keys = [
        _keyDatabasePassword,
        _keyMasterPassword,
        _keyEncryptionKey,
        _keyIV,
      ];
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
  }

  Future<bool> hasMasterPassword() async {
    final hash = await getMasterPasswordHash();
    return hash != null;
  }
}