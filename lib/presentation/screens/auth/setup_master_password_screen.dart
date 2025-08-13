import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/password_strength_indicator.dart';
import '../../widgets/snackbar.dart';
import 'dart:math' as math;

import 'unlock_screen.dart';

class SetupMasterPasswordScreen extends ConsumerStatefulWidget {
  const SetupMasterPasswordScreen({super.key});

  @override
  ConsumerState<SetupMasterPasswordScreen> createState() =>
      _SetupMasterPasswordScreenState();
}

class _SetupMasterPasswordScreenState
    extends ConsumerState<SetupMasterPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _particleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setupMasterPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final repositoryNotifier = ref.read(repositoryStateProvider.notifier);
      
      await authService.setMasterPassword(_passwordController.text);
      await repositoryNotifier.initializeRecordEncryption(_passwordController.text);

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
          } catch (e) {
            if (mounted) {
              CustomSnackBar.showWarning(
                context: context,
                message: 'Failed to enable biometrics: $e',
              );
            }
          }
        }
      }

      if (mounted && isBiometricsAvailable) {
        final shouldEnableBiometrics = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Enable Biometric Authentication'),
            content: const Text(
              'Would you like to enable biometric authentication for quicker access?\n\n'
              'Note: You will still need to enter your master password occasionally for security.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Skip'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Enable'),
              ),
            ],
          ),
        );

        if (shouldEnableBiometrics ?? false) {
          try {
            await authService.setBiometricsEnabled(true);
            // Store the master password for biometric access
            await authService.storeMasterPasswordForBiometrics(_passwordController.text);
            print('Biometrics enabled and master password stored');
          } catch (e) {
            if (mounted) {
              CustomSnackBar.showWarning(
                context: context,
                message: 'Failed to enable biometrics: $e',
              );
            }
          }
        }
      }

      // Just show success message and navigate directly to unlock
      if (mounted) {
        CustomSnackBar.showSuccess(
          context: context,
          message: 'Master password created successfully!',
        );
        
        // Small delay to prevent navigation conflicts
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (mounted) {
          // Navigate directly to unlock screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const UnlockScreen()),
          );
        }
      }
    } catch (e) {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0f0f0f), // Very dark
              Color(0xFF1a1a1a), // Dark marble
              Color(0xFF2d2d2d), // Medium dark
            ],
          ),
        ),
        child: Stack(
          children: [
            // Marble texture overlay
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/marble_texture.png'),
                  fit: BoxFit.cover,
                  opacity: 0.08,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.03),
                    BlendMode.overlay,
                  ),
                ),
              ),
            ),

            // Animated particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SetupParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),

                              // Logo with sparkle effect
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFfbbf24),
                                          Color(0xFFf59e0b),
                                          Color(0xFFd97706),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFfbbf24).withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.security,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // Sparkle animation
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: AnimatedBuilder(
                                      animation: _particleController,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _particleController.value * 2 * 3.14159,
                                          child: const Icon(
                                            Icons.auto_awesome,
                                            color: Color(0xFFfbbf24),
                                            size: 20,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Title with gradient text
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Color(0xFFf3f4f6),
                                    Color(0xFFfbbf24),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Create Your Vault',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                'Choose a strong master password to secure your digital life',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 40),

                              // Warning card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFf59e0b).withOpacity(0.1),
                                      const Color(0xFFd97706).withOpacity(0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFf59e0b).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFf59e0b),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: const Color(0xFFf59e0b),
                                            fontSize: 14,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text: 'Important: ',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(
                                              text: 'This password cannot be recovered if forgotten. Store it safely!',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Password input
                              CustomTextField(
                                controller: _passwordController,
                                labelText: 'Master Password',
                                obscureText: true,
                                autofocus: true,
                                onChanged: (_) => setState(() {}),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < AppConstants.minPasswordLength) {
                                    return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                                  }
                                  
                                  final authService = ref.read(authServiceProvider);
                                  final strength = authService.checkPasswordStrength(value);
                                  if (strength.index < 2) {
                                    return 'Please choose a stronger password';
                                  }
                                  
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password strength indicator
                              if (_passwordController.text.isNotEmpty)
                                PasswordStrengthIndicator(password: _passwordController.text),

                              const SizedBox(height: 24),

                              // Confirm password input
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

                              const SizedBox(height: 40),

                              // Create button
                              CustomButton(
                                text: 'Create Master Password',
                                onPressed: _isLoading ? null : _setupMasterPassword,
                                isLoading: _isLoading,
                                width: double.infinity,
                                icon: Icons.create,
                              ),

                              const SizedBox(height: 32),

                              // Security tips
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF3b82f6).withOpacity(0.1),
                                      const Color(0xFF2563eb).withOpacity(0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFF3b82f6).withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.tips_and_updates,
                                          color: Color(0xFF3b82f6),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Security Tips',
                                          style: TextStyle(
                                            color: const Color(0xFF3b82f6),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildTip('Use a mix of uppercase, lowercase, numbers, and symbols'),
                                        _buildTip('Make it at least 12 characters long'),
                                        _buildTip('Consider using a passphrase like "Coffee\$Moon!2024"'),
                                        _buildTip('Write it down and store it safely offline'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Restore from backup option
                              TextButton(
                                onPressed: _isLoading ? null : () => _showBackupDialog(),
                                child: Text(
                                  'I have an existing backup',
                                  style: TextStyle(
                                    color: const Color(0xFFfbbf24),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: const Color(0xFF3b82f6),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF3b82f6),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.backup,
                color: Color(0xFFfbbf24),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Restore from Backup',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Do you have an existing backup you\'d like to restore?\n\n'
                'You can set up a new master password now and import your backup later from the settings menu.',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Continue Setup',
                onPressed: () => Navigator.of(context).pop(),
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for setup screen particles
class SetupParticlePainter extends CustomPainter {
  final double animationValue;

  SetupParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Create multiple particle systems
    for (int i = 0; i < 20; i++) {
      final progress = (animationValue + i * 0.1) % 1.0;
      final x = size.width * (i * 0.05 + 0.1) + 
                (40 * math.sin(progress * 2 * math.pi));
      final y = size.height * progress;
      
      // Alternate between gold and white particles
      paint.color = i % 2 == 0 
        ? const Color(0xFFfbbf24).withOpacity(0.4)
        : Colors.white.withOpacity(0.3);
      
      final radius = 1 + math.sin(progress * 4 * math.pi) * 1;
      
      canvas.drawCircle(
        Offset(x % size.width, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
