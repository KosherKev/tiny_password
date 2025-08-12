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
      duration: const Duration(milliseconds: 600),
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
    switch (strength) {
      case 0:
        return (const Color(0xFFef4444), 'Too Short', Icons.error_outline);
      case 1:
        return (const Color(0xFFf97316), 'Weak', Icons.warning_amber);
      case 2:
        return (const Color(0xFFf59e0b), 'Fair', Icons.info_outline);
      case 3:
        return (const Color(0xFF84cc16), 'Good', Icons.check_circle_outline);
      case 4:
        return (const Color(0xFF22c55e), 'Strong', Icons.verified);
      default:
        return (Colors.grey, 'Invalid', Icons.help_outline);
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
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar with marble effect
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey[800],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey[800]!,
                            Colors.grey[700]!,
                          ],
                        ),
                      ),
                    ),
                    // Progress fill
                    FractionallySizedBox(
                      widthFactor: progress * _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [
                              color,
                              color.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.password.isNotEmpty) ...[
                const SizedBox(height: 16),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMet
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF22c55e),
                        Color(0xFF16a34a),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey[600]!,
                        Colors.grey[700]!,
                      ],
                    ),
              boxShadow: isMet
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22c55e).withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isMet ? Icons.check : iconData,
                key: ValueKey(isMet),
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 14,
                color: isMet 
                    ? const Color(0xFF22c55e)
                    : Colors.grey[400],
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
              child: Text(text),
            ),
          ),
          if (isMet)
            AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.check_circle,
                size: 16,
                color: const Color(0xFF22c55e),
              ),
            ),
        ],
      ),
    );
  }
}