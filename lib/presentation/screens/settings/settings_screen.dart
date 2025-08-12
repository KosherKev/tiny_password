import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tiny_password/core/constants/app_constants.dart';
import 'package:tiny_password/core/providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _toggleBiometrics() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      final authService = ref.read(authServiceProvider);
      final isBiometricsEnabled = ref.read(isBiometricsEnabledProvider).value ?? false;

      if (!isBiometricsEnabled) {
        final isAvailable = await authService.isBiometricsAvailable();
        if (!isAvailable) {
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication is not available'),
            ),
          );
          return;
        }

        if (!mounted) return;
        // Verify master password before enabling biometrics
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => const _MasterPasswordDialog(),
        );
        
        if (result != true) return;
      }

      await authService.setBiometricsEnabled(!isBiometricsEnabled);
      ref.invalidate(isBiometricsEnabledProvider);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _changeMasterPassword() async {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateToChangeMasterPassword();
  }

  Future<void> _exportData() async {
    try {
      final repository = ref.read(repositoryProvider);
      await repository.exportData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _importData() async {
    try {
      final repository = ref.read(repositoryProvider);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonData = await file.readAsString();
        await repository.importData(jsonData);
      }
      ref.invalidate(allRecordsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data imported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final autoLockDuration = ref.watch(autoLockDurationProvider);
    final isBiometricsEnabled = ref.watch(isBiometricsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance Section
          ListTile(
            title: const Text('Appearance'),
            tileColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(isDarkModeProvider.notifier).state = value;
            },
          ),

          // Security Section
          ListTile(
            title: const Text('Security'),
            tileColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          ListTile(
            title: const Text('Change Master Password'),
            leading: const Icon(Icons.password),
            onTap: _changeMasterPassword,
          ),
          SwitchListTile(
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Use fingerprint or face ID to unlock the app'),
            value: isBiometricsEnabled.value ?? false,
            onChanged: (_) => _toggleBiometrics(),
          ),
          ListTile(
            title: const Text('Auto-Lock Timer'),
            subtitle: Text('Lock after ${autoLockDuration.inMinutes} minutes of inactivity'),
            leading: const Icon(Icons.timer),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => _AutoLockDialog(
                  initialDuration: autoLockDuration,
                ),
              );
            },
          ),

          // Data Management Section
          ListTile(
            title: const Text('Data Management'),
            tileColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Create an encrypted backup of your data'),
            leading: const Icon(Icons.upload),
            onTap: _exportData,
          ),
          ListTile(
            title: const Text('Import Data'),
            subtitle: const Text('Restore data from a backup file'),
            leading: const Icon(Icons.download),
            onTap: _importData,
          ),

          // About Section
          ListTile(
            title: const Text('About'),
            tileColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          ListTile(
            title: const Text('Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
        ],
      ),
    );
  }
}

class _MasterPasswordDialog extends ConsumerStatefulWidget {
  const _MasterPasswordDialog();

  @override
  ConsumerState<_MasterPasswordDialog> createState() => _MasterPasswordDialogState();
}

class _MasterPasswordDialogState extends ConsumerState<_MasterPasswordDialog> {
  final _passwordController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorText = 'Please enter your master password');
      return;
    }

    try {
      final authService = ref.read(authServiceProvider);
      final isValid = await authService.verifyMasterPassword(password);
      if (!mounted) return;

      if (isValid) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _errorText = 'Incorrect master password');
      }
    } catch (e) {
      setState(() => _errorText = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Master Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please enter your master password to enable biometric authentication'),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Master Password',
              errorText: _errorText,
            ),
            onSubmitted: (_) => _verifyPassword(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _verifyPassword,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

class _AutoLockDialog extends ConsumerWidget {
  final Duration initialDuration;

  const _AutoLockDialog({required this.initialDuration});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Auto-Lock Timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select the duration of inactivity before auto-lock:'),
          const SizedBox(height: 16),
          ...AppConstants.autoLockDurations.map(
            (duration) => RadioListTile<int>(
              title: Text('$duration minutes'),
              value: duration,
              groupValue: initialDuration.inMinutes,
              onChanged: (value) {
                if (value != null) {
                  ref.read(autoLockDurationProvider.notifier).state = Duration(minutes: value);
                }
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}