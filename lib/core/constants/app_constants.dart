class AppConstants {
  // App Information
  static const String appName = 'Tiny Password';
  static const String appVersion = '1.0.0';

  // Encryption
  static const int aesKeyLength = 256;
  static const int pbkdf2Iterations = 100000;
  static const int saltLength = 32;

  // Authentication
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;
  static const int defaultPasswordLength = 16;
  static const Duration clipboardClearDuration = Duration(seconds: 30);

  // Auto Lock Durations (in minutes)
  static const List<int> autoLockDurations = [1, 5, 15, 30, 60];
  static const Duration defaultAutoLockDuration = Duration(minutes: 5);

  // Password Generator
  static const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String numberChars = '0123456789';
  static const String specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const String similarChars = 'iIlL1oO0';

  // Database
  static const String dbName = 'tiny_password.db';
  static const int dbVersion = 1;

  // Storage Keys
  static const String masterPasswordHashKey = 'master_password_hash';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String darkModeKey = 'dark_mode';
  static const String autoLockDurationKey = 'auto_lock_duration';

  // Record Field Labels
  static const Map<String, String> loginFields = {
    'username': 'Username',
    'password': 'Password',
    'url': 'Website URL',
  };

  static const Map<String, String> creditCardFields = {
    'cardNumber': 'Card Number',
    'cardholderName': 'Cardholder Name',
    'expiryDate': 'Expiry Date',
    'cvv': 'CVV',
  };

  static const Map<String, String> bankAccountFields = {
    'accountNumber': 'Account Number',
    'routingNumber': 'Routing Number',
    'bankName': 'Bank Name',
    'accountType': 'Account Type',
  };

  // Categories
  static const List<String> defaultCategories = [
    'Personal',
    'Work',
    'Finance',
    'Shopping',
    'Social',
    'Other',
  ];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 2.0;
  static const double iconSize = 24.0;
  static const double buttonHeight = 48.0;
  static const double textFieldHeight = 56.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Error Messages
  static const String errorWeakPassword = 'Password must be at least 8 characters long and contain uppercase, lowercase, numbers, and special characters';
  static const String errorInvalidMasterPassword = 'Invalid master password';
  static const String errorBiometricNotAvailable = 'Biometric authentication is not available on this device';
  static const String errorDatabaseEncryption = 'Failed to encrypt database';
  static const String errorDatabaseDecryption = 'Failed to decrypt database';
  static const String errorExport = 'Failed to export data';
  static const String errorImport = 'Failed to import data';

  // Success Messages
  static const String successPasswordCopied = 'Password copied to clipboard';
  static const String successBackupCreated = 'Backup created successfully';
  static const String successBackupRestored = 'Backup restored successfully';
  static const String successSettingsSaved = 'Settings saved successfully';
  static const String successPasswordChanged = 'Password changed successfully';
  static const String successRecordSaved = 'Record saved successfully';
  static const String successRecordDeleted = 'Record deleted successfully';

  // Confirmation Messages
  static const String confirmDeleteRecord = 'Are you sure you want to delete this record?';
  static const String confirmClearData = 'Are you sure you want to clear all data? This action cannot be undone.';
  static const String confirmImportData = 'Importing data will replace all existing records. Do you want to continue?';

  const AppConstants._();

}