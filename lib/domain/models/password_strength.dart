enum PasswordStrength {
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong;

  String get description {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  String get color {
    switch (this) {
      case PasswordStrength.veryWeak:
        return '#FF0000'; // Red
      case PasswordStrength.weak:
        return '#FF6B6B'; // Light Red
      case PasswordStrength.medium:
        return '#FFD93D'; // Yellow
      case PasswordStrength.strong:
        return '#6BCB77'; // Light Green
      case PasswordStrength.veryStrong:
        return '#4CAF50'; // Green
    }
  }
}