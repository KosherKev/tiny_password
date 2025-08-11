import 'dart:math';

class PasswordGeneratorService {
  static const String _lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numberChars = '0123456789';
  static const String _specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const String _similarChars = 'il1Lo0O';

  final Random _random;

  PasswordGeneratorService() : _random = Random.secure();

  String generatePassword({
    required int length,
    required bool includeLowercase,
    required bool includeUppercase,
    required bool includeNumbers,
    required bool includeSpecial,
    bool excludeSimilarChars = false,
  }) {
    assert(length >= 4, 'Password length must be at least 4 characters');
    assert(
      includeLowercase || includeUppercase || includeNumbers || includeSpecial,
      'At least one character type must be included',
    );

    String charPool = '';
    List<String> mandatoryChars = [];

    // Build character pool and collect mandatory characters
    if (includeLowercase) {
      charPool += _lowercaseChars;
      mandatoryChars.add(_getRandomChar(_lowercaseChars));
    }
    if (includeUppercase) {
      charPool += _uppercaseChars;
      mandatoryChars.add(_getRandomChar(_uppercaseChars));
    }
    if (includeNumbers) {
      charPool += _numberChars;
      mandatoryChars.add(_getRandomChar(_numberChars));
    }
    if (includeSpecial) {
      charPool += _specialChars;
      mandatoryChars.add(_getRandomChar(_specialChars));
    }

    // Remove similar characters if requested
    if (excludeSimilarChars) {
      for (final char in _similarChars.split('')) {
        charPool = charPool.replaceAll(char, '');
      }
    }

    // Generate the password
    List<String> passwordChars = List.filled(length, '');

    // Place mandatory characters at random positions
    for (final char in mandatoryChars) {
      int position;
      do {
        position = _random.nextInt(length);
      } while (passwordChars[position].isNotEmpty);
      passwordChars[position] = char;
    }

    // Fill remaining positions with random characters
    for (int i = 0; i < length; i++) {
      if (passwordChars[i].isEmpty) {
        passwordChars[i] = _getRandomChar(charPool);
      }
    }

    return passwordChars.join();
  }

  String _getRandomChar(String charPool) {
    return charPool[_random.nextInt(charPool.length)];
  }

  bool checkPasswordStrength(String password) {
    if (password.isEmpty) return false;

    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password);
    final hasMinLength = password.length >= 12;

    int strength = 0;
    if (hasLowercase) strength++;
    if (hasUppercase) strength++;
    if (hasNumbers) strength++;
    if (hasSpecial) strength++;
    if (hasMinLength) strength++;

    return strength >= 4;
  }

  Map<String, bool> getPasswordRequirements(String password) {
    return {
      'length': password.length >= 12,
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'number': RegExp(r'[0-9]').hasMatch(password),
      'special': RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password),
    };
  }
}