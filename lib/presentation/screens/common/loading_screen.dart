import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../auth/setup_master_password_screen.dart';
import 'dart:math' as math;

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repositoryState = ref.watch(repositoryStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo with clean geometric design
              AnimatedBuilder(
                animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.security,
                          size: 50,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // App title with clean typography
              Text(
                'Tiny Password',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Secure Password Manager',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Status content
              _buildStatusContent(repositoryState),
              
              const SizedBox(height: 40),
              
              // Loading indicator or action buttons
              _buildLoadingContent(repositoryState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusContent(RepositoryState repositoryState) {
    switch (repositoryState.status) {
      case RepositoryStatus.uninitialized:
        return _buildStatusCard(
          icon: Icons.rocket_launch,
          title: 'Starting up...',
          subtitle: 'Preparing the app for first use',
          color: Theme.of(context).colorScheme.secondary,
        );
        
      case RepositoryStatus.initializing:
        return _buildStatusCard(
          icon: Icons.construction,
          title: 'Initializing secure database...',
          subtitle: 'Setting up encryption and storage',
          color: Theme.of(context).colorScheme.primary,
        );
        
      case RepositoryStatus.error:
        return _buildStatusCard(
          icon: Icons.error_outline,
          title: 'Initialization failed',
          subtitle: _simplifyErrorMessage(repositoryState.error ?? 'Unknown error'),
          color: Theme.of(context).colorScheme.error,
        );
        
      case RepositoryStatus.initialized:
        return _buildStatusCard(
          icon: Icons.check_circle_outline,
          title: 'Ready!',
          subtitle: 'Database initialized successfully',
          color: Theme.of(context).colorScheme.tertiary,
        );
    }
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent(RepositoryState repositoryState) {
    switch (repositoryState.status) {
      case RepositoryStatus.initializing:
        return Column(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please wait...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
        
      case RepositoryStatus.error:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                ref.read(repositoryStateProvider.notifier).retry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final repositoryState = ref.read(repositoryStateProvider);
                if (repositoryState.repository != null) {
                  try {
                    final sqliteRepo = repositoryState.repository!;
                    await sqliteRepo.deleteDatabase();
                    print('Database file deleted during recovery');
                  } catch (e) {
                    print('Could not delete database file: $e');
                  }
                }
                
                final authService = ref.read(authServiceProvider);
                await authService.clearSecureStorage();
                print('Secure storage cleared during recovery');
                
                ref.invalidate(repositoryStateProvider);
                ref.invalidate(hasMasterPasswordProvider);
                ref.invalidate(isBiometricsEnabledProvider);
                
                if (!context.mounted) return;
                
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const SetupMasterPasswordScreen(),
                  ),
                );
              },
              child: Text(
                'Reset App Data',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
        
      case RepositoryStatus.initialized:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Initialization complete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  String _simplifyErrorMessage(String error) {
    if (error.contains('file is not a database')) {
      return 'Database file is corrupted or invalid';
    }
    if (error.contains('path_provider')) {
      return 'Cannot access app storage directory';
    }
    if (error.contains('permission')) {
      return 'Insufficient storage permissions';
    }
    if (error.contains('sqflite') || error.contains('sqlite')) {
      return 'Database initialization error';
    }
    
    return error.length > 100 ? '${error.substring(0, 100)}...' : error;
  }
}