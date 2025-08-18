import 'package:flutter/material.dart';

import '../../presentation/screens/auth/setup_master_password_screen.dart';
import '../../presentation/screens/auth/unlock_screen.dart';

import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/home/generate_password_screen.dart';
import '../../presentation/screens/records/record_details_screen.dart';

import '../../presentation/screens/records/add_edit_record_screen.dart';

import '../../presentation/screens/settings/change_master_password_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  void navigateToSetup() {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const SetupMasterPasswordScreen()),
    );
  }

  void navigateToUnlock() {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const UnlockScreen()),
    );
  }

  void navigateToHome() {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void navigateToSettings() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void navigateToChangeMasterPassword() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const ChangeMasterPasswordScreen()),
    );
  }

  void navigateToAddRecord() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AddEditRecordScreen()),
    );
  }

  void navigateToEditRecord(String recordId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AddEditRecordScreen(recordId: recordId),
      ),
    );
  }

  void navigateToRecordDetails(String recordId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => RecordDetailsScreen(recordId: recordId),
      ),
    );
  }

  void navigateToGeneratePassword() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const GeneratePasswordScreen()),
    );
  }

  void pop() {
    navigatorKey.currentState?.pop();
  }

  void popUntilHome() {
    navigatorKey.currentState?.popUntil(
      (route) => route.isFirst || route.settings.name == '/home',
    );
  }
}