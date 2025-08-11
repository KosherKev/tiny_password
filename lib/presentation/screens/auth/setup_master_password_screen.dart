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
      final authService = ref.read(authServiceProvider);
      await authService.setMasterPassword(_passwordController.text);

      // Check if biometric authentication is available
      final isBiometricsAvailable = await authService.isBiometricsAvailable();

      if (!mounted) return;

      if (isBiometricsAvailable) {
        final shouldEnableBiometrics = await CustomDialog.showConfirmationDialog(
          context: context,
          title: 'Enable Biometric Authentication',
          message:
              'Would you like to enable biometric authentication for quicker access?',
          confirmText: 'Enable',
          cancelText: 'Skip',
        );

        if (shouldEnableBiometrics ?? false) {
          await authService.setBiometricsEnabled(true);
        }
      }

      if (!mounted) return;

      ref.read(navigationServiceProvider).navigateToHome();
      CustomSnackBar.showSuccess(
        context: context,
        message: 'Master password set successfully',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      CustomSnackBar.showError(
        context: context,
        message: e.toString(),
      );
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
            const Text(
              'Create a strong master password to secure your data. This password cannot be recovered if forgotten.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Password Field
            CustomTextField(
              controller: _passwordController,
              labelText: 'Master Password',
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < AppConstants.minPasswordLength) {
                  return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                }
                return null;
              },
            ),

            // Password Strength Indicator
            PasswordStrengthIndicator(password: _passwordController.text),
            const SizedBox(height: 16),

            // Confirm Password Field
            CustomTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              obscureText: true,
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

            // Setup Button
            CustomButton(
              text: 'Set Master Password',
              onPressed: _setupMasterPassword,
              isLoading: _isLoading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}