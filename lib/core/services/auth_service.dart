import 'package:local_auth/local_auth.dart';
import '../constants/app_constants.dart';
import '../encryption/encryption_service.dart';
import '../services/secure_storage_service.dart';
import '../../domain/models/password_strength.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _secureStorage = SecureStorageService();
  final _localAuth = LocalAuthentication();
  final _encryptionService = EncryptionService();

  Future<bool> isMasterPasswordSet() async {
    try {
      final hash = await _secureStorage.getMasterPasswordHash();
      final result = hash != null && hash.isNotEmpty;
      print('Master password check: ${result ? 'exists' : 'not set'}');
      return result;
    } catch (e) {
      print('Error checking master password: $e');
      return false;
    }
  }

  Future<bool> setMasterPassword(String password) async {
    if (password.length < AppConstants.minPasswordLength) {
      throw Exception('Password is too short (minimum ${AppConstants.minPasswordLength} characters)');
    }

    try {
      print('Setting new master password...');
      
      // Reset encryption service first
      _encryptionService.reset();
      
      // Hash the password for storage (authentication)
      final hash = _encryptionService.hashPassword(password);
      await _secureStorage.storeMasterPasswordHash(hash);
      print('Master password hash stored');
      
      // Initialize encryption with the password (for record encryption)
      await _encryptionService.initializeWithMasterPassword(password);
      print('Encryption service initialized with master password');
      
      return true;
    } catch (e) {
      print('Error setting master password: $e');
      _encryptionService.reset();
      throw Exception('Failed to set master password: $e');
    }
  }

  Future<bool> verifyMasterPassword(String password) async {
    try {
      print('Verifying master password...');
      
      final hash = await _secureStorage.getMasterPasswordHash();
      if (hash == null) {
        print('No stored master password hash found');
        return false;
      }

      final isValid = _encryptionService.verifyPassword(password, hash);
      print('Password verification: ${isValid ? 'success' : 'failed'}');
      
      if (isValid) {
        // Initialize encryption service for record operations
        try {
          _encryptionService.reset();
          await _encryptionService.initializeWithMasterPassword(password);
          print('Encryption service initialized after verification');
        } catch (e) {
          print('Failed to initialize encryption after verification: $e');
          throw Exception('Failed to initialize encryption: $e');
        }
      }
      
      return isValid;
    } catch (e) {
      print('Error verifying master password: $e');
      return false;
    }
  }

  Future<bool> changeMasterPassword(String oldPassword, String newPassword) async {
    print('Changing master password...');
    
    if (!await verifyMasterPassword(oldPassword)) {
      throw Exception('Current password is incorrect');
    }

    if (newPassword.length < AppConstants.minPasswordLength) {
      throw Exception('New password is too short (minimum ${AppConstants.minPasswordLength} characters)');
    }

    try {
      // Set the new master password
      await setMasterPassword(newPassword);
      print('Master password changed successfully');
      return true;
    } catch (e) {
      print('Error changing master password: $e');
      throw Exception('Failed to change master password: $e');
    }
  }

  Future<bool> isBiometricsAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final result = isAvailable && isSupported;
      print('Biometrics availability: $result');
      return result;
    } catch (e) {
      print('Error checking biometrics availability: $e');
      return false;
    }
  }

  Future<bool> isBiometricsEnabled() async {
    try {
      // Check if biometrics is available first
      if (!await isBiometricsAvailable()) {
        return false;
      }
      
      // For now, we'll store this preference in secure storage
      // In a real implementation, you might want a separate key for this
      final enabled = await _secureStorage.getBiometricsEnabled();
      print('Biometrics enabled: ${enabled ?? false}');
      return enabled ?? false;
    } catch (e) {
      print('Error checking biometrics enabled: $e');
      return false;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      if (enabled && !await isBiometricsAvailable()) {
        throw Exception('Biometric authentication is not available on this device');
      }
      
      await _secureStorage.setBiometricsEnabled(enabled);
      print('Biometrics preference set to: $enabled');
    } catch (e) {
      print('Error setting biometrics enabled: $e');
      throw Exception('Failed to set biometrics preference: $e');
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!await isBiometricsAvailable() || !await isBiometricsEnabled()) {
      print('Biometrics not available or not enabled');
      return false;
    }

    try {
      print('Attempting biometric authentication...');
      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      print('Biometric authentication result: $result');
      return result;
    } catch (e) {
      print('Error authenticating with biometrics: $e');
      return false;
    }
  }

  /// Store encrypted master password for biometric unlock
  Future<void> storeMasterPasswordForBiometrics(String masterPassword) async {
    try {
      // Simple approach: store the master password hash and use it to verify
      // In production, you'd want to encrypt this with a biometric-protected key
      await _secureStorage.storeBiometricMasterPassword(masterPassword);
      print('Master password stored for biometric access');
    } catch (e) {
      print('Failed to store master password for biometrics: $e');
      throw Exception('Failed to store master password for biometrics: $e');
    }
  }

  /// Get master password for biometric unlock
  Future<String?> getMasterPasswordForBiometrics() async {
    try {
      return await _secureStorage.getBiometricMasterPassword();
    } catch (e) {
      print('Failed to get master password for biometrics: $e');
      return null;
    }
  }

  /// Full biometric unlock with encryption initialization
  Future<bool> unlockWithBiometrics() async {
    final biometricSuccess = await authenticateWithBiometrics();
    if (!biometricSuccess) return false;

    try {
      final masterPassword = await getMasterPasswordForBiometrics();
      if (masterPassword == null) {
        print('No stored master password for biometrics');
        return false;
      }

      // Initialize encryption with the stored master password
      await _encryptionService.initializeWithMasterPassword(masterPassword);
      print('Biometric unlock successful - encryption initialized');
      return true;
    } catch (e) {
      print('Failed to initialize encryption after biometric unlock: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print('Logging out...');
      // Reset encryption service to clear sensitive data from memory
      _encryptionService.reset();
      print('Logout completed');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  PasswordStrength checkPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.veryWeak;
    if (password.length < AppConstants.minPasswordLength) return PasswordStrength.veryWeak;

    int score = 0;
    
    // Length check
    if (password.length >= 12) score += 2;
    else if (password.length >= 8) score += 1;

    // Character variety checks
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score += 1;

    // Determine strength based on score
    if (score <= 1) return PasswordStrength.veryWeak;
    if (score == 2) return PasswordStrength.weak;
    if (score == 3) return PasswordStrength.medium;
    if (score == 4) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  Future<bool> isPasswordStrong(String password) async {
    final strength = checkPasswordStrength(password);
    return strength == PasswordStrength.strong || strength == PasswordStrength.veryStrong;
  }

  Future<void> clearSecureStorage() async {
    try {
      print('Clearing secure storage...');
      await _secureStorage.deleteAll();
      _encryptionService.reset();
      print('Secure storage cleared');
    } catch (e) {
      print('Error clearing secure storage: $e');
      throw Exception('Failed to clear secure storage: $e');
    }
  }

  Future<String?> getMasterPasswordHash() async {
    try {
      return await _secureStorage.getMasterPasswordHash();
    } catch (e) {
      print('Error getting master password hash: $e');
      return null;
    }
  }

  /// Get encryption service instance (for repository initialization)
  EncryptionService get encryptionService => _encryptionService;

  /// Check if encryption is ready for record operations
  bool get isEncryptionReady => _encryptionService.isInitialized;
}