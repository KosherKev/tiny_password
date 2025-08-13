import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiny_password/core/constants/app_constants.dart';
import 'package:tiny_password/core/providers/providers.dart';
import 'dart:math' as math;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _toggleBiometrics() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final authService = ref.read(authServiceProvider);
      final isBiometricsEnabled = ref.read(isBiometricsEnabledProvider).value ?? false;

      if (!isBiometricsEnabled) {
        final isAvailable = await authService.isBiometricsAvailable();
        if (!isAvailable) {
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Biometric authentication is not available'),
              backgroundColor: const Color(0xFFef4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }

        if (!mounted) return;
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => const _MasterPasswordDialog(),
        );
        
        if (result != true) return;
      }

      await authService.setBiometricsEnabled(!isBiometricsEnabled);
      ref.invalidate(isBiometricsEnabledProvider);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFef4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _changeMasterPassword() async {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateToChangeMasterPassword();
  }

  Future<void> _exportData() async {
    try {
      // final repository = ref.read(safeRepositoryProvider);
      // final exportedData = await repository.exportToBackup('backup_password');

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Export functionality coming soon'),
          backgroundColor: const Color(0xFF3b82f6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: const Color(0xFFef4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _importData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Import functionality coming soon'),
          backgroundColor: const Color(0xFF3b82f6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: const Color(0xFFef4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final autoLockDuration = ref.watch(autoLockDurationProvider);
    final isBiometricsEnabled = ref.watch(isBiometricsEnabledProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f0f),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF0f0f0f),
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
                  opacity: 0.05,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.02),
                    BlendMode.overlay,
                  ),
                ),
              ),
            ),

            // Floating particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SettingsParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: CustomScrollView(
                    slivers: [
                      // Modern App Bar
                      SliverAppBar(
                        expandedHeight: 120,
                        floating: false,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
                          title: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFfbbf24),
                                      Color(0xFFf59e0b),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Content
                      SliverPadding(
                        padding: const EdgeInsets.all(24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Appearance Section
                            _buildSectionHeader('Appearance', Icons.palette),
                            const SizedBox(height: 16),
                            _buildSettingCard(
                              child: SwitchListTile(
                                title: const Text(
                                  'Dark Mode',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Switch between light and dark themes',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                value: isDarkMode,
                                onChanged: (value) {
                                  ref.read(isDarkModeProvider.notifier).state = value;
                                },
                                activeColor: const Color(0xFFfbbf24),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Security Section
                            _buildSectionHeader('Security', Icons.security),
                            const SizedBox(height: 16),
                            
                            _buildSettingCard(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFef4444), Color(0xFFdc2626)],
                                    ),
                                  ),
                                  child: const Icon(Icons.password, color: Colors.white, size: 20),
                                ),
                                title: const Text(
                                  'Change Master Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Update your master password',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: _changeMasterPassword,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _buildSettingCard(
                              child: SwitchListTile(
                                secondary: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF3b82f6), Color(0xFF2563eb)],
                                    ),
                                  ),
                                  child: const Icon(Icons.fingerprint, color: Colors.white, size: 20),
                                ),
                                title: const Text(
                                  'Biometric Authentication',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Use fingerprint or face ID to unlock',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                value: isBiometricsEnabled.value ?? false,
                                onChanged: (_) => _toggleBiometrics(),
                                activeColor: const Color(0xFFfbbf24),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _buildSettingCard(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8b5cf6), Color(0xFF7c3aed)],
                                    ),
                                  ),
                                  child: const Icon(Icons.timer, color: Colors.white, size: 20),
                                ),
                                title: const Text(
                                  'Auto-Lock Timer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Lock after ${autoLockDuration.inMinutes} minutes of inactivity',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _AutoLockDialog(
                                      initialDuration: autoLockDuration,
                                    ),
                                  );
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Data Management Section
                            _buildSectionHeader('Data Management', Icons.storage),
                            const SizedBox(height: 16),

                            _buildSettingCard(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF22c55e), Color(0xFF16a34a)],
                                    ),
                                  ),
                                  child: const Icon(Icons.upload, color: Colors.white, size: 20),
                                ),
                                title: const Text(
                                  'Export Data',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Create an encrypted backup of your data',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: _exportData,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _buildSettingCard(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFf59e0b), Color(0xFFd97706)],
                                    ),
                                  ),
                                  child: const Icon(Icons.download, color: Colors.white, size: 20),
                                ),
                                title: const Text(
                                  'Import Data',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Restore data from a backup file',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: _importData,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // About Section
                            _buildSectionHeader('About', Icons.info),
                            const SizedBox(height: 16),

                            _buildSettingCard(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6b7280), Color(0xFF4b5563)],
                                    ),
                                  ),
                                  child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                                ),
                                title: const Text(
                                  'Version',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  AppConstants.appVersion,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),

                            const SizedBox(height: 100),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFfbbf24),
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFfbbf24),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: child,
    );
  }
}

class _MasterPasswordDialog extends ConsumerStatefulWidget {
  const _MasterPasswordDialog();

  @override
  ConsumerState<_MasterPasswordDialog> createState() => _MasterPasswordDialogState();
}

class _MasterPasswordDialogState extends ConsumerState<_MasterPasswordDialog> {
  final _passwordController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorText = 'Please enter your master password');
      return;
    }

    try {
      final authService = ref.read(authServiceProvider);
      final isValid = await authService.verifyMasterPassword(password);
      if (!mounted) return;

      if (isValid) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _errorText = 'Incorrect master password');
      }
    } catch (e) {
      setState(() => _errorText = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              Icons.fingerprint,
              color: Color(0xFFfbbf24),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Verify Master Password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please enter your master password to enable biometric authentication',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Master Password',
                labelStyle: TextStyle(color: Colors.grey[400]),
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFfbbf24)),
                ),
              ),
              onSubmitted: (_) => _verifyPassword(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _verifyPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfbbf24),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Verify'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoLockDialog extends ConsumerWidget {
  final Duration initialDuration;

  const _AutoLockDialog({required this.initialDuration});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
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
              Icons.timer,
              color: Color(0xFFfbbf24),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Auto-Lock Timer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select the duration of inactivity before auto-lock:',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...AppConstants.autoLockDurations.map(
              (duration) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: initialDuration.inMinutes == duration
                        ? const Color(0xFFfbbf24)
                        : Colors.grey[600]!,
                  ),
                ),
                child: RadioListTile<int>(
                  title: Text(
                    '$duration minutes',
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: duration,
                  groupValue: initialDuration.inMinutes,
                  activeColor: const Color(0xFFfbbf24),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(autoLockDurationProvider.notifier).state = Duration(minutes: value);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for settings screen particles
class SettingsParticlePainter extends CustomPainter {
  final double animationValue;

  SettingsParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create gentle floating particles
    for (int i = 0; i < 10; i++) {
      final progress = (animationValue + i * 0.1) % 1.0;
      final x = size.width * (0.05 + i * 0.1) + 
                (25 * math.sin(progress * 2 * math.pi + i));
      final y = size.height * (0.1 + progress * 0.8);
      
      paint.color = i % 3 == 0 
        ? const Color(0xFFfbbf24).withOpacity(0.2)
        : Colors.white.withOpacity(0.1);
      
      final radius = 1.5 + math.sin(progress * 3 * math.pi + i) * 0.5;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}