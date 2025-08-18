import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class PasswordStrengthIndicator extends StatefulWidget {
  final String password;

  const PasswordStrengthIndicator({required this.password, super.key});

  @override
  State<PasswordStrengthIndicator> createState() => _PasswordStrengthIndicatorState();
}

class _PasswordStrengthIndicatorState extends State<PasswordStrengthIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PasswordStrengthIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password) {
      _animationController.reset();
      _animationController.forward();
    }
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

  (Color, String, IconData) _getStrengthProperties(int strength) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    switch (strength) {
      case 0:
        return (
          isDarkMode ? const Color(0xFFF87171) : const Color(0xFFEF4444),
          'Too Short',
          Icons.error_outline
        );
      case 1:
        return (
          isDarkMode ? const Color(0xFFFB923C) : const Color(0xFFF97316),
          'Weak',
          Icons.warning_amber
        );
      case 2:
        return (
          isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B),
          'Fair',
          Icons.info_outline
        );
      case 3:
        return (
          isDarkMode ? const Color(0xFFA3E635) : const Color(0xFF84CC16),
          'Good',
          Icons.check_circle_outline
        );
      case 4:
        return (
          isDarkMode ? const Color(0xFF4ADE80) : const Color(0xFF22C55E),
          'Strong',
          Icons.verified
        );
      default:
        return (
          Theme.of(context).colorScheme.onSurfaceVariant,
          'Invalid',
          Icons.help_outline
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculatePasswordStrength(widget.password);
    final (color, label, icon) = _getStrengthProperties(strength);
    final progress = strength / 4;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with strength indicator
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Password Strength: ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar with clean geometric design
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress * _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (widget.password.isNotEmpty) ...[
                const SizedBox(height: 20),
                ..._buildRequirements(),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildRequirements() {
    final requirements = [
      _buildRequirement(
        'At least ${AppConstants.minPasswordLength} characters',
        widget.password.length >= AppConstants.minPasswordLength,
        Icons.straighten,
      ),
      _buildRequirement(
        'Contains uppercase letter',
        widget.password.contains(RegExp(r'[A-Z]')),
        Icons.keyboard_arrow_up,
      ),
      _buildRequirement(
        'Contains lowercase letter',
        widget.password.contains(RegExp(r'[a-z]')),
        Icons.keyboard_arrow_down,
      ),
      _buildRequirement(
        'Contains number',
        widget.password.contains(RegExp(r'[0-9]')),
        Icons.pin,
      ),
      _buildRequirement(
        'Contains special character',
        widget.password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
        Icons.star_outline,
      ),
    ];

    return requirements;
  }

  Widget _buildRequirement(String text, bool isMet, IconData iconData) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDarkMode ? const Color(0xFF4ADE80) : const Color(0xFF22C55E);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet
                  ? successColor
                  : Theme.of(context).colorScheme.surfaceVariant,
              border: isMet
                  ? null
                  : Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isMet ? Icons.check : iconData,
                key: ValueKey(isMet),
                size: 12,
                color: isMet
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: isMet 
                    ? successColor
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}