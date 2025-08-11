# Tiny Password Manager

A secure, user-friendly password manager built with Flutter that helps you store and manage your sensitive information safely.

## Features

- 256-bit AES encryption for all stored data
- Biometric authentication support
- Multiple record types (passwords, credit cards, secure notes, etc.)
- Password generator
- Auto-lock functionality
- Local backup and restore
- Dark and light theme support
- Search and sort capabilities
- Offline-first architecture

## Architecture

The app follows Clean Architecture principles with the following layers:

```
lib/
├── core/           # Core functionality and utilities
├── data/           # Data layer with repositories and data sources
├── domain/         # Business logic and entities
├── presentation/   # UI layer with screens and widgets
└── main.dart       # Entry point
```

## Getting Started

### Prerequisites

- Flutter SDK
- Android Studio / Xcode
- iOS Simulator / Android Emulator

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/tiny_password.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Security

- All sensitive data is encrypted using AES-256
- Master password is never stored, only its hash
- Automatic app lock when backgrounded
- Secure key derivation using PBKDF2
- Memory protection for sensitive operations

## License

This project is licensed under the MIT License - see the LICENSE file for details.
