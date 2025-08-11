import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../domain/models/password_strength.dart';

class ChangeMasterPasswordScreen extends ConsumerStatefulWidget {
  const ChangeMasterPasswordScreen({super.key});

  @override
  ConsumerState<ChangeMasterPasswordScreen> createState() =>
      _ChangeMasterPasswordScreenState();
}

class _ChangeMasterPasswordScreenState
    extends ConsumerState<ChangeMasterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String _passwordStrength = '';
  Color _strengthColor = Colors.grey;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String password) {
    final authService = ref.read(authServiceProvider);
      final strength = authService.checkPasswordStrength(password);

      setState(() {
        switch (strength) {
          case PasswordStrength.veryWeak:
            _passwordStrength = 'Very Weak';
            _strengthColor = Colors.red.shade900;
            break;
          case PasswordStrength.weak:
            _passwordStrength = 'Weak';
            _strengthColor = Colors.red;
            break;
          case PasswordStrength.medium:
            _passwordStrength = 'Medium';
            _strengthColor = Colors.orange;
            break;
          case PasswordStrength.strong:
            _passwordStrength = 'Strong';
            _strengthColor = Colors.green;
            break;
          case PasswordStrength.veryStrong:
            _passwordStrength = 'Very Strong';
            _strengthColor = Colors.green.shade900;
            break;
        }
    });
  }

  Future<void> _changeMasterPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authService = ref.read(authServiceProvider);

      // Verify current password
      final isCurrentPasswordValid = await authService
          .verifyMasterPassword(_currentPasswordController.text);

      if (!isCurrentPasswordValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current password is incorrect'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Change master password
      await authService.changeMasterPassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Master password changed successfully'),
        ),
      );

      Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Master Password'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Your master password is used to encrypt all your data. Make sure to choose a strong password and remember it, as it cannot be recovered if forgotten.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Current Password
            TextFormField(
              controller: _currentPasswordController,
              obscureText: !_showCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Current Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(
                        () => _showCurrentPassword = !_showCurrentPassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // New Password
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _showNewPassword = !_showNewPassword);
                  },
                ),
              ),
              onChanged: _updatePasswordStrength,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a new password';
                }
                if (value.length < AppConstants.minPasswordLength) {
                  return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                }
                if (_passwordStrength == 'Weak') {
                  return 'Please choose a stronger password';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Password Strength Indicator
            if (_newPasswordController.text.isNotEmpty)
              Text(
                'Password Strength: $_passwordStrength',
                style: TextStyle(color: _strengthColor),
              ),
            const SizedBox(height: 16),

            // Confirm New Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(
                        () => _showConfirmPassword = !_showConfirmPassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _changeMasterPassword,
              child: const Text('Change Master Password'),
            ),
          ],
        ),
      ),
    );
  }
}