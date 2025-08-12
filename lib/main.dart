import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiny_password/core/providers/providers.dart';
import 'core/services/navigation_service.dart';
import 'core/services/password_generator_service.dart';
import 'presentation/screens/auth/setup_master_password_screen.dart';
import 'presentation/screens/auth/unlock_screen.dart';
import 'presentation/screens/common/loading_screen.dart';

// Enhanced debug screen with better error handling
class DebugClearDataScreen extends ConsumerWidget {
  const DebugClearDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repositoryState = ref.watch(repositoryStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Recovery'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Database Initialization Issue',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Status: ${repositoryState.status.name}',
              style: const TextStyle(fontSize: 16),
            ),
            if (repositoryState.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: ${repositoryState.error}',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'This usually happens when:\n'
              '• Database file is corrupted\n'
              '• First time setup\n'
              '• Platform compatibility issues\n\n'
              'You can try to retry or clear all data to start fresh.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Retry button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Initialization'),
                onPressed: () async {
                  try {
                    await ref.read(repositoryStateProvider.notifier).retry();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Retry failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Clear data button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear All Data & Start Fresh'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Clear Data'),
                      content: const Text(
                        'This will permanently delete all stored data including:\n'
                        '• All saved passwords\n'
                        '• App settings\n'
                        '• Master password\n\n'
                        'This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Clear All Data'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed != true) return;
                  
                  try {
                    // Clear auth service data
                    final authService = ref.read(authServiceProvider);
                    await authService.clearSecureStorage();
                    
                    // Clear repository data if possible
                    try {
                      if (repositoryState.repository != null) {
                        await repositoryState.repository!.clearAllData();
                      }
                    } catch (e) {
                      print('Could not clear repository data: $e');
                    }
                    
                    // Invalidate all providers to force refresh
                    ref.invalidate(hasMasterPasswordProvider);
                    ref.invalidate(repositoryStateProvider);
                    
                    if (!context.mounted) return;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data cleared! Restarting app...'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    // Force app restart by reinitializing
                    await Future.delayed(const Duration(seconds: 1));
                    ref.read(repositoryStateProvider.notifier).initialize();
                    
                  } catch (e) {
                    if (!context.mounted) return;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error clearing data: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Force setup button
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const SetupMasterPasswordScreen(),
                  ),
                );
              },
              child: const Text('Force Go to Setup (Skip DB Check)'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling for the entire app
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };
  
  runApp(const ProviderScope(child: TinyPasswordApp()));
}

class TinyPasswordApp extends ConsumerWidget {
  const TinyPasswordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    // Start initialization after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repositoryState = ref.read(repositoryStateProvider);
      if (repositoryState.status == RepositoryStatus.uninitialized) {
        print('Starting repository initialization from main app');
        ref.read(repositoryStateProvider.notifier).initialize();
      }
    });

    return MaterialApp(
      title: 'Tiny Password',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      navigatorKey: NavigationService.navigatorKey,
      home: const AppHome(),
    );
  }
}

class AppHome extends ConsumerWidget {
  const AppHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for repository state changes and show appropriate feedback
    ref.listen(repositoryStateProvider, (previous, next) {
      if (next.status == RepositoryStatus.error && context.mounted) {
        print('Repository error detected: ${next.error}');
        // Don't show snackbar here as we'll show the debug screen
      }
      
      if (next.status == RepositoryStatus.initialized && context.mounted) {
        print('Repository initialized successfully');
      }
    });

    final repoState = ref.watch(repositoryStateProvider);
    
    // Handle different repository states
    switch (repoState.status) {
      case RepositoryStatus.uninitialized:
      case RepositoryStatus.initializing:
        return const LoadingScreen();
        
      case RepositoryStatus.error:
        return const DebugClearDataScreen();
        
      case RepositoryStatus.initialized:
        // Repository is ready, now check authentication
        return const AuthenticationHandler();
    }
  }
}

class AuthenticationHandler extends ConsumerWidget {
  const AuthenticationHandler({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(hasMasterPasswordProvider).when(
      data: (hasPassword) {
        print('Master password check result: $hasPassword');
        
        if (hasPassword) {
          // Master password exists, show unlock screen
          return const UnlockScreen();
        } else {
          // No master password, show setup screen
          return const SetupMasterPasswordScreen();
        }
      },
      loading: () {
        print('Checking master password...');
        return const LoadingScreen();
      },
      error: (error, stack) {
        print('Master password check error: $error');
        print('Stack trace: $stack');
        
        // On error, assume no master password and show setup
        return const SetupMasterPasswordScreen();
      },
    );
  }
}

// Register global providers
final navigationServiceProvider = Provider((ref) => NavigationService());
final passwordGeneratorProvider = Provider((ref) => PasswordGeneratorService());