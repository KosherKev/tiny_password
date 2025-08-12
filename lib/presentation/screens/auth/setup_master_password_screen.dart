import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/password_strength_indicator.dart';
import '../../widgets/snackbar.dart';

class SetupMasterPasswordScreen extends ConsumerStatefulWidget {
  const SetupMasterPasswordScreen({super.key});

  @override
  ConsumerState<SetupMasterPasswordScreen> createState() =>
      _SetupMasterPasswordScreenState();
}

class _SetupMasterPasswordScreenState
    extends ConsumerState<SetupMasterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setupMasterPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('Setting up master password...');
      
      final authService = ref.read(authServiceProvider);
      final repositoryNotifier = ref.read(repositoryStateProvider.notifier);
      
      // Step 1: Set the master password (this also initializes encryption)
      await authService.setMasterPassword(_passwordController.text);
      print('Master password set successfully');

      // Step 2: Initialize record encryption in the repository
      await repositoryNotifier.initializeRecordEncryption(_passwordController.text);
      print('Repository encryption initialized');

      // Step 3: Check if biometric authentication is available
      final isBiometricsAvailable = await authService.isBiometricsAvailable();

      if (mounted && isBiometricsAvailable) {
        final shouldEnableBiometrics = await CustomDialog.showConfirmationDialog(
          context: context,
          title: 'Enable Biometric Authentication',
          message:
              'Would you like to enable biometric authentication for quicker access?\n\n'
              'Note: You will still need to enter your master password occasionally for security.',
          confirmText: 'Enable',
          cancelText: 'Skip',
        );

        if (shouldEnableBiometrics ?? false) {
          try {
            await authService.setBiometricsEnabled(true);
            print('Biometrics enabled');
          } catch (e) {
            print('Failed to enable biometrics: $e');
            if (mounted) {
              CustomSnackBar.showWarning(
                context: context,
                message: 'Failed to enable biometrics: $e',
              );
            }
          }
        }
      }

      // Step 4: Mark as authenticated and navigate to home
      ref.read(isAuthenticatedProvider.notifier).state = true;

      if (mounted) {
        ref.read(navigationServiceProvider).navigateToHome();
        CustomSnackBar.showSuccess(
          context: context,
          message: 'Master password set successfully! Welcome to Tiny Password.',
        );
      }
    } catch (e) {
      print('Setup master password error: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Failed to set up master password: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Setup Master Password',
        showBackButton: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(
              Icons.security,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Create Your Master Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your master password is the key to all your data. Choose a strong password that you\'ll remember.\n\n'
              '⚠️ Important: This password cannot be recovered if forgotten!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Password Field
            CustomTextField(
              controller: _passwordController,
              labelText: 'Master Password',
              obscureText: true,
              autofocus: true,
              onChanged: (_) => setState(() {}), // Trigger rebuild for strength indicator
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < AppConstants.minPasswordLength) {
                  return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                }
                
                // Check password strength
                final authService = ref.read(authServiceProvider);
                final strength = authService.checkPasswordStrength(value);
                if (strength.index < 2) { // Less than medium strength
                  return 'Please choose a stronger password';
                }
                
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Password Strength Indicator
            PasswordStrengthIndicator(password: _passwordController.text),
            const SizedBox(height: 16),

            // Confirm Password Field
            CustomTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Security Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Security Tips',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Use a mix of uppercase, lowercase, numbers, and symbols\n'
                    '• Make it at least 12 characters long\n'
                    '• Avoid common words or personal information\n'
                    '• Consider using a passphrase like "Coffee@Moon!2024"\n'
                    '• Write it down and store it safely',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Setup Button
            CustomButton(
              text: 'Create Master Password',
              onPressed: _isLoading ? null : _setupMasterPassword,
              isLoading: _isLoading,
              width: double.infinity,
            ),
            
            const SizedBox(height: 16),
            
            // Alternative option to restore from backup
            TextButton(
              onPressed: _isLoading ? null : () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Restore from Backup'),
                    content: const Text(
                      'Do you have an existing backup you\'d like to restore?\n\n'
                      'You can set up a new master password now and import your backup later from the settings menu.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Continue Setup'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('I have an existing backup'),
            ),
          ],
        ),
      ),
    );
  }
}