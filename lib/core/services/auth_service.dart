import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/app_constants.dart';
import '../encryption/encryption_service.dart';
import '../../domain/models/password_strength.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _encryptionService = EncryptionService();

  Future<bool> isMasterPasswordSet() async {
    final hash = await _storage.read(key: AppConstants.masterPasswordHashKey);
    return hash != null;
  }

  Future<bool> setMasterPassword(String password) async {
    if (password.length < AppConstants.minPasswordLength) {
      throw Exception('Password is too short');
    }

    final hash = _encryptionService.hashPassword(password);
    await _storage.write(key: AppConstants.masterPasswordHashKey, value: hash);
    await _encryptionService.initialize(password);
    return true;
  }

  Future<bool> verifyMasterPassword(String password) async {
    final hash = await _storage.read(key: AppConstants.masterPasswordHashKey);
    if (hash == null) return false;

    final isValid = _encryptionService.verifyPassword(password, hash);
    if (isValid) {
      await _encryptionService.initialize(password);
    }
    return isValid;
  }

  Future<bool> changeMasterPassword(String oldPassword, String newPassword) async {
    if (!await verifyMasterPassword(oldPassword)) {
      throw Exception('Current password is incorrect');
    }

    if (newPassword.length < AppConstants.minPasswordLength) {
      throw Exception('New password is too short');
    }

    // Re-encrypt all data with new password
    // This should be implemented in coordination with the record repository
    await setMasterPassword(newPassword);
    return true;
  }

  Future<bool> isBiometricsAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricsEnabled() async {
    final enabled = await _storage.read(key: AppConstants.biometricEnabledKey);
    return enabled == 'true';
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(
      key: AppConstants.biometricEnabledKey,
      value: enabled.toString(),
    );
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
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    // Clear sensitive data from memory
    // This should be implemented in coordination with other services
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
    await _storage.deleteAll();
  }
}