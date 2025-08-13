import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiny_password/core/providers/providers.dart';
import 'package:tiny_password/presentation/screens/auth/setup_master_password_screen.dart';
import 'package:tiny_password/presentation/widgets/custom_button.dart';
import 'package:tiny_password/presentation/widgets/snackbar.dart';
import 'package:tiny_password/presentation/widgets/custom_text_field.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isBiometricsAvailable = false;
  late AnimationController _animationController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
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
          _authenticateWithBiometrics();
        }
      }
    } catch (e) {
      print('Error checking biometrics: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      setState(() => _isLoading = true);

      final authService = ref.read(authServiceProvider);
      final repositoryNotifier = ref.read(repositoryStateProvider.notifier);
      
      final success = await authService.unlockWithBiometrics();

      if (success && mounted) {
        // Initialize repository encryption
        await repositoryNotifier.initializeRecordEncryption(
          await authService.getMasterPasswordForBiometrics() ?? ''
        );
        
        ref.read(isAuthenticatedProvider.notifier).state = true;
        
        ref.read(navigationServiceProvider).navigateToHome();
        CustomSnackBar.showSuccess(
          context: context,
          message: 'Biometric unlock successful!',
        );
      } else {
        if (mounted) {
          CustomSnackBar.showError(
            context: context,
            message: 'Biometric authentication failed. Please use your master password.',
          );
        }
      }
    } catch (e) {
      print('Biometric authentication error: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Biometric authentication failed. Please use your master password.',
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

      await repositoryNotifier.initializeRecordEncryption(_passwordController.text);
      ref.read(isAuthenticatedProvider.notifier).state = true;

      if (mounted) {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a1a), // Dark marble
              Color(0xFF2d2d2d), // Medium dark
              Color(0xFF0f0f0f), // Very dark
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
                  opacity: 0.1,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.05),
                    BlendMode.overlay,
                  ),
                ),
              ),
            ),

            // Animated gold particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            SafeArea(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 80),

                              // Logo with marble effect
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFfbbf24), // Gold
                                      Color(0xFFf59e0b), // Darker gold
                                      Color(0xFFd97706), // Amber
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFfbbf24).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Title with marble text effect
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Color(0xFFf3f4f6),
                                    Color(0xFFfbbf24),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                'Enter your master password to unlock your vault',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 60),

                              // Password input with marble styling
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.1),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: CustomTextField(
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
                              ),

                              const SizedBox(height: 32),

                              // Unlock button with gold gradient
                              CustomButton(
                                text: 'Unlock Vault',
                                onPressed: _passwordController.text.isEmpty || _isLoading 
                                  ? null 
                                  : _unlockWithPassword,
                                isLoading: _isLoading,
                                width: double.infinity,
                              ),

                              if (_isBiometricsAvailable) ...[
                                const SizedBox(height: 24),
                                
                                // Divider with marble styling
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.grey[600]!,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'or use',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.grey[600]!,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Biometric button
                                CustomButton(
                                  text: 'Biometric Authentication',
                                  onPressed: _isLoading ? null : _authenticateWithBiometrics,
                                  icon: Icons.fingerprint,
                                  isOutlined: true,
                                  width: double.infinity,
                                ),
                              ],

                              const SizedBox(height: 40),

                              // Forgot password with marble styling
                              TextButton(
                                onPressed: () => _showResetConfirmation(),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: const Color(0xFFfbbf24),
                                    fontSize: 16,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Security notice
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFfbbf24).withOpacity(0.1),
                                      const Color(0xFFf59e0b).withOpacity(0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFfbbf24).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.security,
                                      color: Color(0xFFfbbf24),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your data is protected with military-grade AES-256 encryption',
                                        style: TextStyle(
                                          color: const Color(0xFFfbbf24),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
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

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        title: Text(
          'Forgot Password?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Unfortunately, your master password cannot be recovered. '
          'If you\'ve forgotten it, you\'ll need to clear all app data '
          'and start fresh.\n\n'
          'This will permanently delete all your saved passwords.',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[400],
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _showFinalResetConfirmation();
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  void _showFinalResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
        title: Text(
          'Clear All Data',
          style: TextStyle(
            color: Colors.red[400],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will permanently delete:\n'
          '• All saved passwords\n'
          '• All app settings\n'
          '• Master password\n\n'
          'This action cannot be undone.',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[400],
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                // Perform complete reset
                final authService = ref.read(authServiceProvider);
                await authService.clearSecureStorage();
                
                final repositoryState = ref.read(repositoryStateProvider);
                if (repositoryState.repository != null) {
                  try {
                    final sqliteRepo = repositoryState.repository!;
                    await sqliteRepo.deleteDatabase();
                    print('Database file deleted');
                  } catch (e) {
                    print('Could not delete database file: $e');
                  }
                  
                  try {
                    await repositoryState.repository!.dispose();
                    print('Repository disposed');
                  } catch (e) {
                    print('Could not dispose repository: $e');
                  }
                }
                
                // Invalidate all providers
                ref.invalidate(hasMasterPasswordProvider);
                ref.invalidate(repositoryStateProvider);
                ref.invalidate(isBiometricsEnabledProvider);
                
                if (mounted) {
                  CustomSnackBar.showSuccess(
                    context: context,
                    message: 'All data cleared. Redirecting to setup...',
                  );
                  
                  // Navigate to setup screen
                  await Future.delayed(const Duration(seconds: 1));
                  
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const SetupMasterPasswordScreen(),
                      ),
                      (route) => false,
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  CustomSnackBar.showError(
                    context: context,
                    message: 'Failed to clear data: $e',
                  );
                  
                  // Force navigation to setup anyway
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const SetupMasterPasswordScreen(),
                    ),
                    (route) => false,
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

// Custom painter for floating gold particles
class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFfbbf24).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Create floating particles
    for (int i = 0; i < 15; i++) {
      final x = (size.width * (i * 0.1 + 0.1)) + 
                (20 * math.sin(animationValue * 2 * math.pi + i));
      final y = (size.height * (i * 0.05 + 0.1)) + 
                (30 * math.cos(animationValue * 2 * math.pi + i * 0.5));
      
      canvas.drawCircle(
        Offset(x % size.width, y % size.height),
        2 + math.sin(animationValue * 4 * math.pi + i) * 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}