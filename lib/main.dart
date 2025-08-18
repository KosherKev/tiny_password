import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiny_password/core/providers/providers.dart';
import 'core/services/navigation_service.dart';
import 'core/services/password_generator_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/setup_master_password_screen.dart';
import 'presentation/screens/auth/unlock_screen.dart';
import 'presentation/screens/common/loading_screen.dart';
import 'presentation/screens/home/home_screen.dart';

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

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of text fields
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        title: 'Guardian',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        navigatorKey: NavigationService.navigatorKey,
        home: const AppHome(),
      ),
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
        return const SetupMasterPasswordScreen();
        
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
          // Master password exists, check if user is authenticated
          final isAuthenticated = ref.watch(isAuthenticatedProvider);
          
          if (isAuthenticated) {
            return const HomeScreen(); // Only go to home if authenticated
          } else {
            return const UnlockScreen(); // Show unlock screen
          }
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
        
        // On error, show setup screen (safer fallback)
        return const SetupMasterPasswordScreen();
      },
    );
  }
}

// Register global providers
final navigationServiceProvider = Provider((ref) => NavigationService());
final passwordGeneratorProvider = Provider((ref) => PasswordGeneratorService());