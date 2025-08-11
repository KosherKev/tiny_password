import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({required this.password, super.key});

  @override
  Widget build(BuildContext context) {
    final strength = _calculatePasswordStrength(password);
    final (color, label) = _getStrengthProperties(strength, context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: strength / 4,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          'Password Strength: $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
        if (password.isNotEmpty) ..._buildRequirements(context),
      ],
    );
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= AppConstants.minPasswordLength) strength++;
    if (password.length >= 12) strength++;

    // Character variety checks
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    // Normalize strength to 0-4 range
    return (strength / 6 * 4).floor();
  }

  (Color, String) _getStrengthProperties(int strength, BuildContext context) {
    switch (strength) {
      case 0:
        return (Colors.grey, 'Too Short');
      case 1:
        return (Colors.red, 'Weak');
      case 2:
        return (Colors.orange, 'Fair');
      case 3:
        return (Colors.yellow, 'Good');
      case 4:
        return (Colors.green, 'Strong');
      default:
        return (Colors.grey, 'Invalid');
    }
  }

  List<Widget> _buildRequirements(BuildContext context) {
    final requirements = [
      _buildRequirement(
        context,
        'At least ${AppConstants.minPasswordLength} characters',
        password.length >= AppConstants.minPasswordLength,
      ),
      _buildRequirement(
        context,
        'Contains uppercase letter',
        password.contains(RegExp(r'[A-Z]')),
      ),
      _buildRequirement(
        context,
        'Contains lowercase letter',
        password.contains(RegExp(r'[a-z]')),
      ),
      _buildRequirement(
        context,
        'Contains number',
        password.contains(RegExp(r'[0-9]')),
      ),
      _buildRequirement(
        context,
        'Contains special character',
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];

    return [
      const SizedBox(height: 8),
      ...requirements,
    ];
  }

  Widget _buildRequirement(BuildContext context, String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet
                ? Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}