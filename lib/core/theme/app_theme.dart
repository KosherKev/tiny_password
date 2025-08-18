import 'package:flutter/material.dart';

class AppTheme {
  // Bauhaus inspired color palette
  static const Color bauhausRed = Color(0xFFE53E3E);
  static const Color bauhausBlue = Color(0xFF3182CE);
  static const Color bauhausYellow = Color(0xFFD69E2E);
  static const Color bauhausBlack = Color(0xFF1A202C);
  static const Color bauhausWhite = Color(0xFFFFFFF3);
  
  // Modern interpretations
  static const Color modernRed = Color(0xFFEF4444);
  static const Color modernBlue = Color(0xFF3B82F6);
  static const Color modernYellow = Color(0xFFF59E0B);
  static const Color modernGreen = Color(0xFF10B981);
  static const Color modernPurple = Color(0xFF8B5CF6);
  static const Color modernOrange = Color(0xFFF97316);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme (Bauhaus inspired)
    colorScheme: const ColorScheme.light(
      primary: bauhausBlue,
      onPrimary: bauhausWhite,
      primaryContainer: Color(0xFFBFDBFE),
      onPrimaryContainer: Color(0xFF1E3A8A),
      
      secondary: bauhausYellow,
      onSecondary: bauhausBlack,
      secondaryContainer: Color(0xFFFEF3C7),
      onSecondaryContainer: Color(0xFF92400E),
      
      tertiary: bauhausRed,
      onTertiary: bauhausWhite,
      tertiaryContainer: Color(0xFFFECDD3),
      onTertiaryContainer: Color(0xFF991B1B),
      
      error: modernRed,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF991B1B),
      
      surface: bauhausWhite,
      onSurface: bauhausBlack,
      surfaceVariant: Color(0xFFF8FAFC),
      onSurfaceVariant: Color(0xFF475569),
      
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFFE2E8F0),
      
      background: Color(0xFFFAFAFA),
      onBackground: bauhausBlack,
      
      inverseSurface: Color(0xFF334155),
      onInverseSurface: Color(0xFFF1F5F9),
      inversePrimary: Color(0xFF93C5FD),
    ),

    // App Bar Theme (Flat design)
    appBarTheme: const AppBarTheme(
      elevation: 0, // Flat design - no elevation
      scrolledUnderElevation: 1,
      backgroundColor: bauhausWhite,
      foregroundColor: bauhausBlack,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: bauhausBlack,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),

    // Card Theme (Geometric Bauhaus style)
    // cardTheme: CardTheme(
    //   elevation: 0, // Flat design
    //   color: bauhausWhite,
    //   surfaceTintColor: Colors.transparent,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(8), // Geometric corners
    //     side: const BorderSide(
    //       color: Color(0xFFE2E8F0),
    //       width: 1,
    //     ),
    //   ),
    //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    // ),

    // Input Decoration (Clean flat style)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      
      // Geometric borders
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: bauhausBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: modernRed,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: modernRed,
          width: 2,
        ),
      ),
    ),

    // Button Themes (Geometric Bauhaus style)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0, // Flat design
        backgroundColor: bauhausBlue,
        foregroundColor: bauhausWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: bauhausBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: bauhausBlue,
        side: const BorderSide(color: bauhausBlue, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // Typography (Clean, functional)
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: bauhausBlack,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: bauhausBlack,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: bauhausBlack,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: bauhausBlack,
        letterSpacing: 0.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: bauhausBlack,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: bauhausBlack,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: bauhausBlack,
        letterSpacing: 0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: bauhausBlack,
        letterSpacing: 0.25,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: bauhausBlack,
        letterSpacing: 0.5,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: bauhausBlack,
        letterSpacing: 0.15,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: bauhausBlack,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF64748B),
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: bauhausBlack,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: bauhausBlack,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return bauhausBlue;
          }
          return const Color(0xFF94A3B8);
        },
      ),
      trackColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return bauhausBlue.withOpacity(0.3);
          }
          return const Color(0xFFE2E8F0);
        },
      ),
    ),

    // List Tile Theme
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dense: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
      space: 1,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Dark Color Scheme (Bauhaus inspired)
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF60A5FA), // Lighter blue for dark mode
      onPrimary: bauhausBlack,
      primaryContainer: Color(0xFF1E3A8A),
      onPrimaryContainer: Color(0xFFBFDBFE),
      
      secondary: Color(0xFFFBBF24), // Lighter yellow for dark mode
      onSecondary: bauhausBlack,
      secondaryContainer: Color(0xFF92400E),
      onSecondaryContainer: Color(0xFFFEF3C7),
      
      tertiary: Color(0xFFF87171), // Lighter red for dark mode
      onTertiary: bauhausBlack,
      tertiaryContainer: Color(0xFF991B1B),
      onTertiaryContainer: Color(0xFFFECDD3),
      
      error: Color(0xFFF87171),
      onError: bauhausBlack,
      errorContainer: Color(0xFF991B1B),
      onErrorContainer: Color(0xFFFEE2E2),
      
      surface: Color(0xFF1E293B),
      onSurface: Color(0xFFF1F5F9),
      surfaceVariant: Color(0xFF334155),
      onSurfaceVariant: Color(0xFFCBD5E1),
      
      outline: Color(0xFF64748B),
      outlineVariant: Color(0xFF475569),
      
      background: Color(0xFF0F172A),
      onBackground: Color(0xFFF1F5F9),
      
      inverseSurface: Color(0xFFF1F5F9),
      onInverseSurface: Color(0xFF334155),
      inversePrimary: bauhausBlue,
    ),

    // App Bar Theme (Dark)
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Color(0xFFF1F5F9),
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),

    // Card Theme (Dark)
    // cardTheme: CardTheme(
    //   elevation: 0,
    //   color: const Color(0xFF1E293B),
    //   surfaceTintColor: Colors.transparent,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(8),
    //     side: const BorderSide(
    //       color: Color(0xFF475569),
    //       width: 1,
    //     ),
    //   ),
    //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    // ),

    // Input Decoration (Dark)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF334155),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF64748B),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF64748B),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF60A5FA),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFF87171),
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFF87171),
          width: 2,
        ),
      ),
    ),

    // Button Themes (Dark)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF60A5FA),
        foregroundColor: bauhausBlack,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF60A5FA),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF60A5FA),
        side: const BorderSide(color: Color(0xFF60A5FA), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // Typography (Dark mode)
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF1F5F9),
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
        letterSpacing: 0.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
        letterSpacing: 0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
        letterSpacing: 0.25,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
        letterSpacing: 0.5,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFFF1F5F9),
        letterSpacing: 0.15,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFFF1F5F9),
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF1F5F9),
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF1F5F9),
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    ),

    // Switch Theme (Dark)
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF60A5FA);
          }
          return const Color(0xFF64748B);
        },
      ),
      trackColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF60A5FA).withOpacity(0.3);
          }
          return const Color(0xFF475569);
        },
      ),
    ),

    // List Tile Theme (Dark)
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dense: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),

    // Divider Theme (Dark)
    dividerTheme: const DividerThemeData(
      color: Color(0xFF475569),
      thickness: 1,
      space: 1,
    ),
  );

  // Utility methods for record type colors
  static Color getRecordTypeColor(String recordType, bool isDarkMode) {
    switch (recordType.toLowerCase()) {
      case 'login':
        return isDarkMode ? const Color(0xFF60A5FA) : bauhausBlue;
      case 'creditcard':
        return isDarkMode ? const Color(0xFFF87171) : bauhausRed;
      case 'bankaccount':
        return isDarkMode ? const Color(0xFF34D399) : modernGreen;
      case 'note':
        return isDarkMode ? const Color(0xFFFBBF24) : bauhausYellow;
      case 'address':
        return isDarkMode ? const Color(0xFFA78BFA) : modernPurple;
      case 'identity':
        return isDarkMode ? const Color(0xFFFF8A65) : modernOrange;
      case 'wifi':
        return isDarkMode ? const Color(0xFF4DD0E1) : const Color(0xFF0891B2);
      case 'software':
        return isDarkMode ? const Color(0xFFAED581) : const Color(0xFF65A30D);
      case 'server':
        return isDarkMode ? const Color(0xFFFFB74D) : const Color(0xFFEA580C);
      case 'document':
        return isDarkMode ? const Color(0xFFE1BEE7) : const Color(0xFF9333EA);
      case 'membership':
        return isDarkMode ? const Color(0xFF81C784) : const Color(0xFF059669);
      case 'vehicle':
        return isDarkMode ? const Color(0xFF90A4AE) : const Color(0xFF475569);
      default:
        return isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    }
  }
}