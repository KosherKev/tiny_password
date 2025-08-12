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
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      print('Error checking master password: $e');
      return false;
    }
  }

  Future<bool> setMasterPassword(String password) async {
    if (password.length < AppConstants.minPasswordLength) {
      throw Exception('Password is too short');
    }

    try {
      // Reset encryption service first
      _encryptionService.reset();
      
      // Hash the password for storage
      final hash = _encryptionService.hashPassword(password);
      await _secureStorage.storeMasterPasswordHash(hash);
      
      // Initialize encryption with the new password
      await _encryptionService.initialize(password);
      
      return true;
    } catch (e) {
      print('Error setting master password: $e');
      throw Exception('Failed to set master password: $e');
    }
  }

  Future<bool> verifyMasterPassword(String password) async {
    try {
      final hash = await _secureStorage.getMasterPasswordHash();
      if (hash == null) return false;

      final isValid = _encryptionService.verifyPassword(password, hash);
      if (isValid) {
        // Reset and reinitialize encryption service
        _encryptionService.reset();
        await _encryptionService.initialize(password);
      }
      return isValid;
    } catch (e) {
      print('Error verifying master password: $e');
      return false;
    }
  }

  Future<bool> changeMasterPassword(String oldPassword, String newPassword) async {
    if (!await verifyMasterPassword(oldPassword)) {
      throw Exception('Current password is incorrect');
    }

    if (newPassword.length < AppConstants.minPasswordLength) {
      throw Exception('New password is too short');
    }

    try {
      // Set the new master password
      await setMasterPassword(newPassword);
      return true;
    } catch (e) {
      print('Error changing master password: $e');
      throw Exception('Failed to change master password: $e');
    }
  }

  Future<bool> isBiometricsAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking biometrics availability: $e');
      return false;
    }
  }

  Future<bool> isBiometricsEnabled() async {
    try {
      // For now, return false since we don't have a way to store this securely
      // In a real app, you'd store this in secure storage
      return false;
    } catch (e) {
      print('Error checking biometrics enabled: $e');
      return false;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      // For now, do nothing since we don't have secure storage for this
      // In a real app, you'd store this preference securely
      print('Biometrics enabled: $enabled');
    } catch (e) {
      print('Error setting biometrics enabled: $e');
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!await isBiometricsAvailable() || !await isBiometricsEnabled()) {
      return false;
    }

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Error authenticating with biometrics: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Reset encryption service
      _encryptionService.reset();
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
      await _secureStorage.deleteAll();
      _encryptionService.reset();
    } catch (e) {
      print('Error clearing secure storage: $e');
    }
  }
}