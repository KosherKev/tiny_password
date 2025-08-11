import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/password_generator_service.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/snackbar.dart';

final passwordGeneratorProvider = Provider((ref) => PasswordGeneratorService());

class GeneratePasswordScreen extends ConsumerStatefulWidget {
  const GeneratePasswordScreen({super.key});

  @override
  ConsumerState<GeneratePasswordScreen> createState() =>
      _GeneratePasswordScreenState();
}

class _GeneratePasswordScreenState extends ConsumerState<GeneratePasswordScreen> {
  String _generatedPassword = '';
  int _passwordLength = 16;
  bool _includeLowercase = true;
  bool _includeUppercase = true;
  bool _includeNumbers = true;
  bool _includeSpecial = true;
  bool _excludeSimilar = false;

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
      CustomSnackBar.showError(
        context: context,
        message: 'Failed to generate password: ${e.toString()}',
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_generatedPassword.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _generatedPassword));
    if (!mounted) return;

    CustomSnackBar.showSuccess(
      context: context,
      message: 'Password copied to clipboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canGenerate = _includeLowercase ||
        _includeUppercase ||
        _includeNumbers ||
        _includeSpecial;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Generate Password',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Generated Password Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _generatedPassword.isEmpty
                      ? 'No password generated yet'
                      : _generatedPassword,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (_generatedPassword.isNotEmpty) ...[                  
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Copy to Clipboard',
                    onPressed: _copyToClipboard,
                    icon: Icons.copy,
                    isOutlined: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Password Length Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Password Length'),
              Text('$_passwordLength characters'),
            ],
          ),
          Slider(
            value: _passwordLength.toDouble(),
            min: 4,
            max: 32,
            divisions: 28,
            label: _passwordLength.toString(),
            onChanged: (value) {
              setState(() {
                _passwordLength = value.round();
              });
            },
          ),
          const SizedBox(height: 16),

          // Character Type Options
          const Text('Include Characters:'),
          const SizedBox(height: 8),
          _buildCheckbox(
            'Lowercase (a-z)',
            _includeLowercase,
            (value) => setState(() => _includeLowercase = value!),
          ),
          _buildCheckbox(
            'Uppercase (A-Z)',
            _includeUppercase,
            (value) => setState(() => _includeUppercase = value!),
          ),
          _buildCheckbox(
            'Numbers (0-9)',
            _includeNumbers,
            (value) => setState(() => _includeNumbers = value!),
          ),
          _buildCheckbox(
            'Special Characters (!@#\$%^&*)',
            _includeSpecial,
            (value) => setState(() => _includeSpecial = value!),
          ),
          const SizedBox(height: 16),

          // Additional Options
          const Text('Additional Options:'),
          const SizedBox(height: 8),
          _buildCheckbox(
            'Exclude Similar Characters (1, l, I, 0, O)',
            _excludeSimilar,
            (value) => setState(() => _excludeSimilar = value!),
          ),
          const SizedBox(height: 24),

          // Generate Button
          CustomButton(
            text: 'Generate Password',
            onPressed: canGenerate ? _generatePassword : null,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    void Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}