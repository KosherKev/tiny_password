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
  late AnimationController _particleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repositoryState = ref.watch(repositoryStateProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0f0f0f),
              Color(0xFF1a1a1a),
              Color(0xFF2d2d2d),
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
                  painter: LoadingParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated logo with marble effect
                      AnimatedBuilder(
                        animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
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
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.security,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // App title with gradient
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFf3f4f6),
                            Color(0xFFfbbf24),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Tiny Password',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Secure Password Manager',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
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
            ),
          ],
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
          color: const Color(0xFF3b82f6),
        );
        
      case RepositoryStatus.initializing:
        return _buildStatusCard(
          icon: Icons.construction,
          title: 'Initializing secure database...',
          subtitle: 'Setting up encryption and storage',
          color: const Color(0xFFfbbf24),
        );
        
      case RepositoryStatus.error:
        return _buildStatusCard(
          icon: Icons.error_outline,
          title: 'Initialization failed',
          subtitle: _simplifyErrorMessage(repositoryState.error ?? 'Unknown error'),
          color: const Color(0xFFef4444),
        );
        
      case RepositoryStatus.initialized:
        return _buildStatusCard(
          icon: Icons.check_circle_outline,
          title: 'Ready!',
          subtitle: 'Database initialized successfully',
          color: const Color(0xFF22c55e),
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
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
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
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFfbbf24)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please wait...',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        );
        
      case RepositoryStatus.error:
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFfbbf24),
                    Color(0xFFf59e0b),
                  ],
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(repositoryStateProvider.notifier).retry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
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
                'Show Recovery Options',
                style: TextStyle(
                  color: const Color(0xFFfbbf24),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
        
      case RepositoryStatus.initialized:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF22c55e).withOpacity(0.1),
                const Color(0xFF16a34a).withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF22c55e).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF22c55e),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Initialization complete',
                style: TextStyle(
                  color: const Color(0xFF22c55e),
                  fontSize: 14,
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

// Custom painter for loading screen particles
class LoadingParticlePainter extends CustomPainter {
  final double animationValue;

  LoadingParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create orbiting particles around the center
    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < 12; i++) {
      final angle = (animationValue * 2 * math.pi) + (i * math.pi / 6);
      final radius = 100 + (20 * math.sin(animationValue * 4 * math.pi + i));
      
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      paint.color = i % 2 == 0 
        ? const Color(0xFFfbbf24).withOpacity(0.6)
        : Colors.white.withOpacity(0.4);
      
      final particleRadius = 2 + math.sin(animationValue * 6 * math.pi + i) * 1;
      
      canvas.drawCircle(
        Offset(x, y),
        particleRadius,
        paint,
      );
    }

    // Add some floating particles
    for (int i = 0; i < 8; i++) {
      final progress = (animationValue + i * 0.125) % 1.0;
      final x = size.width * (i * 0.125 + 0.1) + 
                (30 * math.sin(progress * 2 * math.pi));
      final y = size.height * progress;
      
      paint.color = const Color(0xFFfbbf24).withOpacity(0.3);
      
      canvas.drawCircle(
        Offset(x % size.width, y),
        1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}