import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiny_password/core/providers/providers.dart';
import 'core/services/navigation_service.dart';
import 'core/services/password_generator_service.dart';
import 'presentation/screens/auth/setup_master_password_screen.dart';
import 'presentation/screens/auth/unlock_screen.dart';
import 'presentation/screens/common/loading_screen.dart';

// Temporary debug screen
class DebugClearDataScreen extends ConsumerWidget {
  const DebugClearDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Clear Data'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Debug Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'The app detected existing data. Use the button below to clear everything and start fresh.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  // Clear auth service data
                  final authService = ref.read(authServiceProvider);
                  await authService.clearSecureStorage();
                  
                  // Clear repository data if possible
                  try {
                    final repository = ref.read(repositoryProvider);
                    await repository.clearAllData();
                  } catch (e) {
                    print('Could not clear repository data: $e');
                  }
                  
                  // Invalidate all providers to force refresh
                  ref.invalidate(hasMasterPasswordProvider);
                  ref.invalidate(repositoryStateProvider);
                  
                  if (!context.mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data cleared! App will restart...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Force app restart by invalidating everything
                  await Future.delayed(const Duration(seconds: 1));
                  ref.read(repositoryStateProvider.notifier).initialize();
                  
                } catch (e) {
                  if (!context.mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Clear All Data & Restart'),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                // Force navigate to setup screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const SetupMasterPasswordScreen(),
                  ),
                );
              },
              child: const Text('Force Go to Setup'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TinyPasswordApp()));
}

class TinyPasswordApp extends ConsumerWidget {
  const TinyPasswordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    // Start initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(repositoryStateProvider.notifier).initialize();
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
    // Listen for repository errors and show snackbar
    ref.listen(repositoryStateProvider, (previous, next) {
      if (next.status == RepositoryStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Repository Error: ${next.error}'))
        );
      }
    });

    final repoState = ref.watch(repositoryStateProvider);

    // Show loading screen while repository is initializing
    if (repoState.status != RepositoryStatus.initialized) {
      return const LoadingScreen();
    }

    // Once repository is initialized, handle authentication flow
    return ref.watch(hasMasterPasswordProvider).when(
      data: (hasPassword) {
        print('Has master password: $hasPassword'); // Debug log
        
        // TEMPORARY: Show debug screen if there's a mismatch
        // Remove this in production
        if (hasPassword) {
          return const DebugClearDataScreen();
        }
        
        return hasPassword 
          ? const UnlockScreen() 
          : const SetupMasterPasswordScreen();
      },
      loading: () => const LoadingScreen(),
      error: (error, stack) {
        print('Auth check error: $error'); // Debug log
        // On error, assume no master password is set
        return const SetupMasterPasswordScreen();
      },
    );
  }
}

// Register global providers
final navigationServiceProvider = Provider((ref) => NavigationService());
final passwordGeneratorProvider = Provider((ref) => PasswordGeneratorService());