import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiny_password/core/providers/providers.dart';
import 'core/services/navigation_service.dart';
import 'core/services/password_generator_service.dart';
import 'presentation/screens/auth/setup_master_password_screen.dart';
import 'presentation/screens/auth/unlock_screen.dart';

void main() {
  runApp(const ProviderScope(child: TinyPasswordApp()));
}

class TinyPasswordApp extends ConsumerWidget {
  const TinyPasswordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final hasMasterPassword = ref.watch(hasMasterPasswordProvider);

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
      // Replace the home line with this:
      home: ref.watch(hasMasterPasswordProvider).when(
        data: (hasPassword) => hasPassword 
          ? const UnlockScreen() 
          : const SetupMasterPasswordScreen(),
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const SetupMasterPasswordScreen(),
      ),
    );
  }
}

// Register global providers
final navigationServiceProvider = Provider((ref) => NavigationService());
final passwordGeneratorProvider = Provider((ref) => PasswordGeneratorService());
