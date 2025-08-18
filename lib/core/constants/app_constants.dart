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
  static const String viewModeKey = 'view_mode'; // New: for record type vs category view

  // Record Field Labels - Login
  static const Map<String, String> loginFields = {
    'username': 'Username',
    'password': 'Password',
    'url': 'Website URL',
    'email': 'Email',
    'twoFactorSecret': 'Two-Factor Secret',
  };

  // Record Field Labels - Credit Card
  static const Map<String, String> creditCardFields = {
    'cardNumber': 'Card Number',
    'cardholderName': 'Cardholder Name',
    'expiryDate': 'Expiry Date',
    'cvv': 'CVV',
    'pin': 'PIN',
    'issuer': 'Issuer',
  };

  // Record Field Labels - Bank Account
  static const Map<String, String> bankAccountFields = {
    'accountNumber': 'Account Number',
    'routingNumber': 'Routing Number',
    'bankName': 'Bank Name',
    'accountType': 'Account Type',
    'swiftCode': 'SWIFT Code',
    'ibanNumber': 'IBAN Number',
  };

  // Record Field Labels - Address
  static const Map<String, String> addressFields = {
    'addressLine1': 'Address Line 1',
    'addressLine2': 'Address Line 2',
    'city': 'City',
    'state': 'State/Province',
    'postalCode': 'Postal Code',
    'country': 'Country',
    'addressType': 'Address Type', // Home, Work, Shipping, etc.
  };

  // Record Field Labels - Identity
  static const Map<String, String> identityFields = {
    'documentType': 'Document Type',
    'documentNumber': 'Document Number',
    'fullName': 'Full Name',
    'dateOfBirth': 'Date of Birth',
    'issueDate': 'Issue Date',
    'expiryDate': 'Expiry Date',
    'issuingAuthority': 'Issuing Authority',
    'nationality': 'Nationality',
  };

  // Record Field Labels - WiFi
  static const Map<String, String> wifiFields = {
    'networkName': 'Network Name (SSID)',
    'password': 'Password',
    'securityType': 'Security Type',
    'frequency': 'Frequency (2.4GHz/5GHz)',
    'location': 'Location',
  };

  // Record Field Labels - Software
  static const Map<String, String> softwareFields = {
    'softwareName': 'Software Name',
    'licenseKey': 'License Key',
    'version': 'Version',
    'purchaseDate': 'Purchase Date',
    'expiryDate': 'Expiry Date',
    'vendor': 'Vendor',
    'downloadUrl': 'Download URL',
  };

  // Record Field Labels - Server
  static const Map<String, String> serverFields = {
    'serverName': 'Server Name',
    'ipAddress': 'IP Address',
    'port': 'Port',
    'username': 'Username',
    'password': 'Password',
    'privateKey': 'Private Key',
    'protocol': 'Protocol',
    'location': 'Location',
  };

  // Record Field Labels - Document
  static const Map<String, String> documentFields = {
    'documentTitle': 'Document Title',
    'documentType': 'Document Type',
    'documentNumber': 'Document Number',
    'issueDate': 'Issue Date',
    'expiryDate': 'Expiry Date',
    'issuingOrganization': 'Issuing Organization',
    'fileLocation': 'File Location',
  };

  // Record Field Labels - Membership
  static const Map<String, String> membershipFields = {
    'organizationName': 'Organization Name',
    'membershipNumber': 'Membership Number',
    'membershipType': 'Membership Type',
    'username': 'Username',
    'password': 'Password',
    'startDate': 'Start Date',
    'expiryDate': 'Expiry Date',
    'benefits': 'Benefits',
  };

  // Record Field Labels - Vehicle
  static const Map<String, String> vehicleFields = {
    'vehicleMake': 'Make',
    'vehicleModel': 'Model',
    'year': 'Year',
    'licensePlate': 'License Plate',
    'vin': 'VIN',
    'registrationNumber': 'Registration Number',
    'insurancePolicy': 'Insurance Policy',
    'insuranceCompany': 'Insurance Company',
  };

  // Categories - Enhanced list
  static const List<String> defaultCategories = [
    'Personal',
    'Work',
    'Finance',
    'Shopping',
    'Social',
    'Education',
    'Travel',
    'Gaming',
    'Health',
    'Utilities',
    'Entertainment',
    'Business',
    'Sports',
    'News',
    'Streaming',
    'Other',
  ];

  // Record Types - Complete list with display info
  static const Map<String, RecordTypeInfo> recordTypes = {
    'login': RecordTypeInfo(
      name: 'Login Credentials',
      description: 'Usernames, passwords, and website logins',
      icon: 'key',
      color: 'blue',
    ),
    'creditCard': RecordTypeInfo(
      name: 'Payment Cards',
      description: 'Credit cards, debit cards, and payment info',
      icon: 'credit_card',
      color: 'red',
    ),
    'bankAccount': RecordTypeInfo(
      name: 'Bank Accounts',
      description: 'Bank accounts, routing numbers, and financial info',
      icon: 'account_balance',
      color: 'green',
    ),
    'note': RecordTypeInfo(
      name: 'Secure Notes',
      description: 'Private notes and text information',
      icon: 'note',
      color: 'yellow',
    ),
    'address': RecordTypeInfo(
      name: 'Addresses',
      description: 'Home, work, and shipping addresses',
      icon: 'location_on',
      color: 'purple',
    ),
    'identity': RecordTypeInfo(
      name: 'Identity Documents',
      description: 'Passports, licenses, and ID documents',
      icon: 'badge',
      color: 'orange',
    ),
    'wifi': RecordTypeInfo(
      name: 'WiFi Networks',
      description: 'Network passwords and connection details',
      icon: 'wifi',
      color: 'cyan',
    ),
    'software': RecordTypeInfo(
      name: 'Software Licenses',
      description: 'License keys and software credentials',
      icon: 'memory',
      color: 'lime',
    ),
    'server': RecordTypeInfo(
      name: 'Server Access',
      description: 'Server credentials and connection info',
      icon: 'dns',
      color: 'amber',
    ),
    'document': RecordTypeInfo(
      name: 'Documents',
      description: 'Important documents and references',
      icon: 'description',
      color: 'indigo',
    ),
    'membership': RecordTypeInfo(
      name: 'Memberships',
      description: 'Club memberships and subscriptions',
      icon: 'card_membership',
      color: 'teal',
    ),
    'vehicle': RecordTypeInfo(
      name: 'Vehicles',
      description: 'Vehicle registration and insurance info',
      icon: 'directions_car',
      color: 'grey',
    ),
  };

  // Address Types
  static const List<String> addressTypes = [
    'Home',
    'Work',
    'Shipping',
    'Billing',
    'Emergency Contact',
    'Other',
  ];

  // Document Types for Identity
  static const List<String> identityDocumentTypes = [
    'Passport',
    'Driver\'s License',
    'National ID',
    'Social Security Card',
    'Birth Certificate',
    'Marriage Certificate',
    'Visa',
    'Green Card',
    'Other',
  ];

  // Software Categories
  static const List<String> softwareCategories = [
    'Operating System',
    'Productivity',
    'Development Tools',
    'Security',
    'Media',
    'Games',
    'Utilities',
    'Other',
  ];

  // Security Types for WiFi
  static const List<String> wifiSecurityTypes = [
    'WPA3',
    'WPA2',
    'WPA',
    'WEP',
    'Open',
    'Enterprise',
  ];

  // Account Types for Bank Accounts
  static const List<String> bankAccountTypes = [
    'Checking',
    'Savings',
    'Credit',
    'Investment',
    'Money Market',
    'Certificate of Deposit',
    'Business',
    'Other',
  ];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 0.0; // Flat design
  static const double iconSize = 24.0;
  static const double buttonHeight = 48.0;
  static const double textFieldHeight = 56.0;

  // Grid Layout Constants
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 1.2;
  static const double gridSpacing = 16.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 250);
  static const Duration longAnimation = Duration(milliseconds: 400);

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

// Helper class for record type information
class RecordTypeInfo {
  final String name;
  final String description;
  final String icon;
  final String color;

  const RecordTypeInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}