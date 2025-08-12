import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyDatabasePassword = 'database_password';
  static const _keyMasterPassword = 'master_password_hash';
  static const _keyEncryptionKey = 'encryption_key';
  static const _keyIV = 'encryption_iv';

  Future<void> storeDatabasePassword(String password) async {
    await _storage.write(key: _keyDatabasePassword, value: password);
  }

  Future<String?> getDatabasePassword() async {
    return await _storage.read(key: _keyDatabasePassword);
  }

  Future<void> storeMasterPasswordHash(String hash) async {
    await _storage.write(key: _keyMasterPassword, value: hash);
  }

  Future<String?> getMasterPasswordHash() async {
    return await _storage.read(key: _keyMasterPassword);
  }

  Future<void> storeEncryptionKey(String key) async {
    await _storage.write(key: _keyEncryptionKey, value: key);
  }

  Future<String?> getEncryptionKey() async {
    return await _storage.read(key: _keyEncryptionKey);
  }

  Future<void> storeIV(String iv) async {
    await _storage.write(key: _keyIV, value: iv);
  }

  Future<String?> getIV() async {
    return await _storage.read(key: _keyIV);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasMasterPassword() async {
    final hash = await getMasterPasswordHash();
    return hash != null;
  }
}