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

      if (mounted) {
        setState(() {
          _isBiometricsAvailable = isAvailable && isEnabled;
        });

        if (_isBiometricsAvailable) {
          // Auto-trigger biometric authentication if available
          _authenticateWithBiometrics();
        }
      }
    } catch (e) {
      print('Error checking biometrics: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Failed to check biometric availability',
        );
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      setState(() => _isLoading = true);

      final authService = ref.read(authServiceProvider);
      final success = await authService.authenticateWithBiometrics();

      if (success && mounted) {
        // Biometric auth succeeded, but we still need to initialize encryption
        // For now, we'll need the user to enter the password once more
        // In a production app, you'd want to securely store the master password
        // or derive it from biometric data
        
        CustomSnackBar.showSuccess(
          context: context,
          message: 'Biometric authentication successful',
        );
        
        // For now, still require password entry
        // TODO: Implement secure master password storage for biometric auth
      }
    } catch (e) {
      print('Biometric authentication error: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Biometric authentication failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unlockWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final authService = ref.read(authServiceProvider);
      final repositoryNotifier = ref.read(repositoryStateProvider.notifier);
      
      // Step 1: Verify master password
      print('Verifying master password...');
      final isValid = await authService.verifyMasterPassword(_passwordController.text);

      if (!isValid) {
        if (mounted) {
          CustomSnackBar.showError(
            context: context,
            message: 'Invalid password',
          );
        }
        return;
      }

      print('Master password verified successfully');

      // Step 2: Initialize record encryption with the master password
      try {
        await repositoryNotifier.initializeRecordEncryption(_passwordController.text);
        print('Record encryption initialized');
      } catch (e) {
        print('Failed to initialize record encryption: $e');
        throw Exception('Failed to initialize encryption: $e');
      }

      // Step 3: Mark as authenticated and navigate
      ref.read(isAuthenticatedProvider.notifier).state = true;

      if (mounted) {
        print('Navigating to home screen');
        ref.read(navigationServiceProvider).navigateToHome();
        
        CustomSnackBar.showSuccess(
          context: context,
          message: 'Welcome back!',
        );
      }
    } catch (e) {
      print('Unlock error: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: e.toString(),
        );
      }
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
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter your master password to unlock the app.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

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
              onPressed: _passwordController.text.isEmpty || _isLoading 
                ? null 
                : _unlockWithPassword,
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

            const SizedBox(height: 32),

            // Forgot Password Help
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Forgot Password?'),
                    content: const Text(
                      'Unfortunately, your master password cannot be recovered. '
                      'If you\'ve forgotten it, you\'ll need to clear all app data '
                      'and start fresh.\n\n'
                      'This will permanently delete all your saved passwords.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showResetConfirmation();
                        },
                        child: const Text('Clear All Data'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete:\n'
          '• All saved passwords\n'
          '• All app settings\n'
          '• Master password\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                final authService = ref.read(authServiceProvider);
                await authService.clearSecureStorage();
                
                final repositoryNotifier = ref.read(repositoryStateProvider.notifier);
                await repositoryNotifier.clearAllData();
                
                // Invalidate providers to refresh state
                ref.invalidate(hasMasterPasswordProvider);
                ref.invalidate(repositoryStateProvider);
                
                if (mounted) {
                  CustomSnackBar.showSuccess(
                    context: context,
                    message: 'All data cleared. Please set up a new master password.',
                  );
                }
              } catch (e) {
                if (mounted) {
                  CustomSnackBar.showError(
                    context: context,
                    message: 'Failed to clear data: $e',
                  );
                }
              }
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }
}