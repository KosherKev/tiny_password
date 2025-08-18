import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/password_generator_service.dart';
import '../../widgets/custom_button.dart';

final passwordGeneratorProvider = Provider((ref) => PasswordGeneratorService());

class GeneratePasswordScreen extends ConsumerStatefulWidget {
  const GeneratePasswordScreen({super.key});

  @override
  ConsumerState<GeneratePasswordScreen> createState() =>
      _GeneratePasswordScreenState();
}

class _GeneratePasswordScreenState extends ConsumerState<GeneratePasswordScreen>
    with TickerProviderStateMixin {
  String _generatedPassword = '';
  int _passwordLength = 16;
  bool _includeLowercase = true;
  bool _includeUppercase = true;
  bool _includeNumbers = true;
  bool _includeSpecial = true;
  bool _excludeSimilar = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    
    // Generate initial password
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePassword();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    try {
      final generator = ref.read(passwordGeneratorProvider);
      final password = generator.generatePassword(
        length: _passwordLength,
        includeLowercase: _includeLowercase,
        includeUppercase: _includeUppercase,
        includeNumbers: _includeNumbers,
        includeSpecial: _includeSpecial,
        excludeSimilarChars: _excludeSimilar,
      );

      setState(() {
        _generatedPassword = password;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate password: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_generatedPassword.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _generatedPassword));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password copied to clipboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canGenerate = _includeLowercase ||
        _includeUppercase ||
        _includeNumbers ||
        _includeSpecial;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Generate Password'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Generated Password Display
                    _buildPasswordDisplay(canGenerate),
                    const SizedBox(height: 32),

                    // Length Control
                    _buildLengthControl(),
                    const SizedBox(height: 32),

                    // Character Options
                    _buildCharacterOptions(),
                    const SizedBox(height: 32),

                    // Advanced Options
                    _buildAdvancedOptions(),
                    const SizedBox(height: 32),

                    // Generate Button
                    CustomButton(
                      text: 'Generate New Password',
                      onPressed: canGenerate ? _generatePassword : null,
                      width: double.infinity,
                      icon: Icons.refresh,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordDisplay(bool canGenerate) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Generated Password',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: SelectableText(
              _generatedPassword.isEmpty
                  ? 'No password generated yet'
                  : _generatedPassword,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_generatedPassword.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Copy',
                    onPressed: _copyToClipboard,
                    icon: Icons.copy,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Regenerate',
                    onPressed: canGenerate ? _generatePassword : null,
                    icon: Icons.refresh,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLengthControl() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.straighten,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Password Length',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_passwordLength characters',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.secondary,
              inactiveTrackColor: Theme.of(context).colorScheme.surfaceVariant,
              thumbColor: Theme.of(context).colorScheme.secondary,
              overlayColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              valueIndicatorColor: Theme.of(context).colorScheme.secondary,
            ),
            child: Slider(
              value: _passwordLength.toDouble(),
              min: 4,
              max: 64,
              divisions: 60,
              label: _passwordLength.toString(),
              onChanged: (value) {
                setState(() {
                  _passwordLength = value.round();
                });
              },
              onChangeEnd: (_) => _generatePassword(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '4',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '64',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterOptions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.keyboard,
                color: Theme.of(context).colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Character Types',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            'Lowercase Letters (a-z)',
            'abcdefghijklmnopqrstuvwxyz',
            _includeLowercase,
            (value) {
              setState(() => _includeLowercase = value);
              _generatePassword();
            },
            Icons.keyboard_arrow_down,
          ),
          _buildOptionTile(
            'Uppercase Letters (A-Z)',
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
            _includeUppercase,
            (value) {
              setState(() => _includeUppercase = value);
              _generatePassword();
            },
            Icons.keyboard_arrow_up,
          ),
          _buildOptionTile(
            'Numbers (0-9)',
            '0123456789',
            _includeNumbers,
            (value) {
              setState(() => _includeNumbers = value);
              _generatePassword();
            },
            Icons.pin,
          ),
          _buildOptionTile(
            'Special Characters',
            '!@#\$%^&*()_+-=[]{}|;:,.<>?',
            _includeSpecial,
            (value) {
              setState(() => _includeSpecial = value);
              _generatePassword();
            },
            Icons.star_outline,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Advanced Options',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            'Exclude Similar Characters',
            'Avoid confusing characters like i, I, l, L, 1, o, O, 0',
            _excludeSimilar,
            (value) {
              setState(() => _excludeSimilar = value);
              _generatePassword();
            },
            Icons.visibility_off,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(
            icon,
            color: value 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: EdgeInsets.zero,
        ),
        if (!isLast)
          Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            height: 16,
          ),
      ],
    );
  }
}