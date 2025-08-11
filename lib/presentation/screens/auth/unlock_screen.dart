import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/snackbar.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isBiometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final authService = ref.read(authServiceProvider);
      final isAvailable = await authService.isBiometricsAvailable();
      final isEnabled = await authService.isBiometricsEnabled();

      setState(() {
        _isBiometricsAvailable = isAvailable && isEnabled;
      });

      if (_isBiometricsAvailable) {
        _authenticateWithBiometrics();
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(
        context: context,
        message: 'Failed to check biometric availability',
      );
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      setState(() => _isLoading = true);

      final authService = ref.read(authServiceProvider);
      final success = await authService.authenticateWithBiometrics();

      if (success && mounted) {
        ref.read(navigationServiceProvider).navigateToHome();
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(
        context: context,
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unlockWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final authService = ref.read(authServiceProvider);
      final isValid =
          await authService.verifyMasterPassword(_passwordController.text);

      if (!isValid) {
        if (!mounted) return;
        CustomSnackBar.showError(
          context: context,
          message: 'Invalid password',
        );
        return;
      }

      if (!mounted) return;
      ref.read(navigationServiceProvider).navigateToHome();
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(
        context: context,
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Unlock App',
        showBackButton: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Enter your master password to unlock the app.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Password Field
            CustomTextField(
              controller: _passwordController,
              labelText: 'Master Password',
              obscureText: true,
              autofocus: !_isBiometricsAvailable,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Unlock Button
            CustomButton(
              text: 'Unlock',
              onPressed:
                  _passwordController.text.isEmpty ? null : _unlockWithPassword,
              isLoading: _isLoading,
              width: double.infinity,
            ),

            if (_isBiometricsAvailable) ...[              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Biometric Button
              CustomButton(
                text: 'Use Biometrics',
                onPressed: _isLoading ? null : _authenticateWithBiometrics,
                icon: Icons.fingerprint,
                isOutlined: true,
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }
}