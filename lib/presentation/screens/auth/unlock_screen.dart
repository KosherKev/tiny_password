import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiny_password/core/providers/providers.dart';
import 'package:tiny_password/core/services/auto_lock_service.dart';
import 'package:tiny_password/presentation/screens/auth/setup_master_password_screen.dart';
import 'package:tiny_password/presentation/widgets/custom_button.dart';
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
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

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
      
      final success = await authService.unlockWithBiometrics();

      if (success && mounted) {
        ref.read(isAuthenticatedProvider.notifier).state = true;
        
        ref.read(navigationServiceProvider).navigateToHome();
        _showSnackBar('Biometric unlock successful!');
      } else {
        if (mounted) {
          _showSnackBar(
            'Biometric authentication failed. Please use your master password.',
            isError: true,
          );
        }
      }
    } catch (e) {
      print('Biometric authentication error: $e');
      if (mounted) {
        _showSnackBar(
          'Biometric authentication failed. Please use your master password.',
          isError: true,
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
      
      final isValid = await authService.verifyMasterPassword(_passwordController.text);

      if (!isValid) {
        if (mounted) {
          _showSnackBar('Invalid password', isError: true);
        }
        return;
      }

      ref.read(isAuthenticatedProvider.notifier).state = true;
      
      // Start auto-lock timer after successful authentication
      ref.read(autoLockServiceProvider).onAuthenticated();

      if (mounted) {
        ref.read(navigationServiceProvider).navigateToHome();
        _showSnackBar('Welcome back!');
      }
    } catch (e) {
      print('Unlock error: $e');
      if (mounted) {
        _showSnackBar(e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
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

                        // Logo with Bauhaus styling
                        _buildLogo(context),

                        const SizedBox(height: 40),

                        // Title
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Enter your master password to unlock your vault',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 60),

                        // Password input
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

                        const SizedBox(height: 32),

                        // Unlock button
                        CustomButton(
                          text: 'Unlock Vault',
                          onPressed: _passwordController.text.isEmpty || _isLoading 
                            ? null 
                            : _unlockWithPassword,
                          isLoading: _isLoading,
                          width: double.infinity,
                          icon: Icons.lock_open,
                        ),

                        if (_isBiometricsAvailable) ...[
                          const SizedBox(height: 24),
                          
                          // Divider
                          _buildDivider(context),

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

                        // Forgot password
                        TextButton(
                          onPressed: () => _showResetConfirmation(),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Security notice
                        _buildSecurityNotice(context),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        Icons.lock_outline,
        size: 60,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or use',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your data is protected with military-grade AES-256 encryption',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        title: Text(
          'Forgot Password?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Unfortunately, your master password cannot be recovered. '
          'If you\'ve forgotten it, you\'ll need to clear all app data '
          'and start fresh.\n\n'
          'This will permanently delete all your saved passwords.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          ),
        ),
        title: Text(
          'Clear All Data',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will permanently delete:\n'
          '• All saved passwords\n'
          '• All app settings\n'
          '• Master password\n\n'
          'This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
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
                  _showSnackBar('All data cleared. Redirecting to setup...');
                  
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
                  _showSnackBar('Failed to clear data: $e', isError: true);
                  
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