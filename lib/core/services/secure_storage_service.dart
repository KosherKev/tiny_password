import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  FlutterSecureStorage? _storage;
  SharedPreferences? _prefs;
  bool _useSecureStorage = true;
  bool _initialized = false;
  
  static const _keyBiometricMasterPassword = 'tiny_password_biometric_master_v2';
  static const _keyEncryptionSalt = 'tiny_password_encryption_salt_v2';
  static const _keyDatabasePassword = 'tiny_password_db_password_v2';
  static const _keyMasterPassword = 'tiny_password_master_hash_v2';
  static const _keyEncryptionKey = 'tiny_password_encryption_key_v2';
  static const _keyIV = 'tiny_password_iv_v2';
  static const _keyBiometricsEnabled = 'tiny_password_biometrics_v2';

  Future<void> _initStorage() async {
    if (_initialized) return;

    await clearKeychainOnFirstLaunch();
    
    try {
      print('Initializing secure storage...');
      
      // Configure secure storage with platform-specific options
      AndroidOptions androidOptions = const AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      );
      
      IOSOptions iosOptions = const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      );
      
      _storage = FlutterSecureStorage(
        aOptions: androidOptions,
        iOptions: iosOptions,
      );
      
      // Test if secure storage works
      await _storage!.write(key: 'test_key', value: 'test_value');
      final testValue = await _storage!.read(key: 'test_key');
      await _storage!.delete(key: 'test_key');
      
      if (testValue == 'test_value') {
        print('Secure storage test successful');
        _useSecureStorage = true;
      } else {
        throw Exception('Secure storage test failed');
      }
    } catch (e) {
      print('Secure storage not available, falling back to SharedPreferences: $e');
      _useSecureStorage = false;
      
      try {
        _prefs = await SharedPreferences.getInstance();
        print('SharedPreferences fallback initialized');
      } catch (e2) {
        print('Failed to initialize SharedPreferences: $e2');
        throw Exception('No storage method available: $e2');
      }
    }
    
    _initialized = true;
  }

  Future<void> _write(String key, String value) async {
    await _initStorage();

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
      try {
        final encoded = base64.encode(utf8.encode(value));
        await _prefs!.setString(key, encoded);
        print('Stored $key using SharedPreferences fallback');
      } catch (e) {
        print('SharedPreferences write failed: $e');
        throw Exception('Failed to store data: $e');
      }
    } else {
      throw Exception('No storage method available');
    }
  }

  Future<String?> _read(String key) async {
    await _initStorage();

    if (_useSecureStorage && _storage != null) {
      try {
        final value = await _storage!.read(key: key);
        if (value != null) {
          return value;
        }
      } catch (e) {
        print('Secure storage read failed, falling back: $e');
        _useSecureStorage = false;
        _prefs ??= await SharedPreferences.getInstance();
      }
    }

    // Fallback to SharedPreferences
    if (_prefs != null) {
      try {
        final encoded = _prefs!.getString(key);
        if (encoded != null) {
          return utf8.decode(base64.decode(encoded));
        }
      } catch (e) {
        print('SharedPreferences read failed for key $key: $e');
        return null;
      }
    }

    return null;
  }

  Future<bool> _writeBool(String key, bool value) async {
    await _initStorage();

    if (_useSecureStorage && _storage != null) {
      try {
        await _storage!.write(key: key, value: value.toString());
        return true;
      } catch (e) {
        print('Secure storage bool write failed, falling back: $e');
        _useSecureStorage = false;
        _prefs ??= await SharedPreferences.getInstance();
      }
    }

    // Fallback to SharedPreferences
    if (_prefs != null) {
      try {
        await _prefs!.setBool(key, value);
        return true;
      } catch (e) {
        print('SharedPreferences bool write failed: $e');
        return false;
      }
    }

    return false;
  }

  Future<bool?> _readBool(String key) async {
    await _initStorage();

    if (_useSecureStorage && _storage != null) {
      try {
        final value = await _storage!.read(key: key);
        if (value != null) {
          return value.toLowerCase() == 'true';
        }
      } catch (e) {
        print('Secure storage bool read failed, falling back: $e');
        _useSecureStorage = false;
        _prefs ??= await SharedPreferences.getInstance();
      }
    }

    // Fallback to SharedPreferences
    if (_prefs != null) {
      try {
        return _prefs!.getBool(key);
      } catch (e) {
        print('SharedPreferences bool read failed for key $key: $e');
        return null;
      }
    }

    return null;
  }

  Future<void> storeDatabasePassword(String password) async {
    try {
      await _write(_keyDatabasePassword, password);
      print('Database password stored successfully');
    } catch (e) {
      print('Failed to store database password: $e');
      throw Exception('Failed to store database password: $e');
    }
  }

  Future<String?> getDatabasePassword() async {
    try {
      final password = await _read(_keyDatabasePassword);
      print('Database password retrieved: ${password != null ? 'found' : 'not found'}');
      return password;
    } catch (e) {
      print('Failed to get database password: $e');
      return null;
    }
  }

  Future<void> storeMasterPasswordHash(String hash) async {
    try {
      await _write(_keyMasterPassword, hash);
      print('Master password hash stored successfully');
    } catch (e) {
      print('Failed to store master password hash: $e');
      throw Exception('Failed to store master password hash: $e');
    }
  }

  Future<String?> getMasterPasswordHash() async {
    try {
      final hash = await _read(_keyMasterPassword);
      print('Master password hash value: $hash');
      print('Master password hash retrieved: ${hash != null ? 'found' : 'not found'}');
      return hash;
    } catch (e) {
      print('Failed to get master password hash: $e');
      return null;
    }
  }

  Future<void> storeEncryptionKey(String key) async {
    try {
      await _write(_keyEncryptionKey, key);
      print('Encryption key stored successfully');
    } catch (e) {
      print('Failed to store encryption key: $e');
      throw Exception('Failed to store encryption key: $e');
    }
  }

  Future<String?> getEncryptionKey() async {
    try {
      final key = await _read(_keyEncryptionKey);
      print('Encryption key retrieved: ${key != null ? 'found' : 'not found'}');
      return key;
    } catch (e) {
      print('Failed to get encryption key: $e');
      return null;
    }
  }

  Future<void> storeIV(String iv) async {
    try {
      await _write(_keyIV, iv);
      print('IV stored successfully');
    } catch (e) {
      print('Failed to store IV: $e');
      throw Exception('Failed to store IV: $e');
    }
  }

  Future<String?> getIV() async {
    try {
      final iv = await _read(_keyIV);
      print('IV retrieved: ${iv != null ? 'found' : 'not found'}');
      return iv;
    } catch (e) {
      print('Failed to get IV: $e');
      return null;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      await _writeBool(_keyBiometricsEnabled, enabled);
      print('Biometrics enabled preference stored: $enabled');
    } catch (e) {
      print('Failed to store biometrics preference: $e');
      throw Exception('Failed to store biometrics preference: $e');
    }
  }

  Future<bool?> getBiometricsEnabled() async {
    try {
      final enabled = await _readBool(_keyBiometricsEnabled);
      print('Biometrics enabled preference retrieved: ${enabled ?? 'not set'}');
      return enabled;
    } catch (e) {
      print('Failed to get biometrics preference: $e');
      return null;
    }
  }

  Future<void> deleteAll() async {
    try {
      await _initStorage();
      
      if (_useSecureStorage && _storage != null) {
        try {
          await _storage!.deleteAll();
          print('Secure storage cleared successfully');
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
          _keyBiometricsEnabled,
        ];
        for (final key in keys) {
          await _prefs!.remove(key);
        }
        print('SharedPreferences cleared successfully');
      }
      
      // Reset instance state after clearing storage
      _initialized = false;
      _storage = null;
      _prefs = null;
      _useSecureStorage = true;
      await _initStorage();
      
    } catch (e) {
      print('Failed to clear storage: $e');
      throw Exception('Failed to clear storage: $e');
    }
  }

  Future<bool> hasMasterPassword() async {
    try {
      final hash = await getMasterPasswordHash();
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      print('Failed to check master password: $e');
      return false;
    }
  }

  /// Check if secure storage is being used (for debugging)
  bool get isUsingSecureStorage => _useSecureStorage;

  /// Force reinitialization (for testing)
  Future<void> reinitialize() async {
    _initialized = false;
    _storage = null;
    _prefs = null;
    _useSecureStorage = true;
    await _initStorage();
  }

  Future<void> clearKeychainOnFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if this is first launch after reinstall
      if (prefs.getBool('is_first_app_launch') ?? true) {
        print('First launch detected - clearing ALL storage');
        
        // Clear ALL secure storage completely
        if (_storage != null) {
          await _storage!.deleteAll();
          print('Secure storage cleared completely');
        }
        
        // Force clear SharedPreferences completely
        await prefs.clear();
        print('SharedPreferences cleared completely');
        
        // Reset internal state
        _initialized = false;
        _storage = null;
        _prefs = null;
        _useSecureStorage = true;
        
        // Re-mark first launch (since we just cleared prefs)
        await prefs.setBool('is_first_app_launch', false);
        
        print('Complete storage reset on first launch');
      }
    } catch (e) {
      print('Error clearing storage on first launch: $e');
    }
  }

  Future<void> storeEncryptionSalt(String salt) async {
    try {
      await _write(_keyEncryptionSalt, salt);
      print('Encryption salt stored successfully');
    } catch (e) {
      print('Failed to store encryption salt: $e');
      throw Exception('Failed to store encryption salt: $e');
    }
  }

  Future<String?> getEncryptionSalt() async {
    try {
      final salt = await _read(_keyEncryptionSalt);
      print('Encryption salt retrieved: ${salt != null ? 'found' : 'not found'}');
      return salt;
    } catch (e) {
      print('Failed to get encryption salt: $e');
      return null;
    }
  }

  Future<void> storeBiometricMasterPassword(String password) async {
    try {
      await _write(_keyBiometricMasterPassword, password);
      print('Biometric master password stored successfully');
    } catch (e) {
      print('Failed to store biometric master password: $e');
      throw Exception('Failed to store biometric master password: $e');
    }
  }

  Future<String?> getBiometricMasterPassword() async {
    try {
      final password = await _read(_keyBiometricMasterPassword);
      print('Biometric master password retrieved: ${password != null ? 'found' : 'not found'}');
      return password;
    } catch (e) {
      print('Failed to get biometric master password: $e');
      return null;
    }
  }
}