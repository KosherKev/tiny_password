import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    CustomSnackBarAction? action,
    bool showIcon = true,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          if (showIcon) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(context, type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(type),
                size: 16,
                color: _getIconColor(context, type),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _getTextColor(context, type),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: duration,
      backgroundColor: _getBackgroundColor(context, type),
      action: action != null
          ? SnackBarAction(
              label: action.label,
              onPressed: action.onPressed,
              textColor: _getActionTextColor(context, type),
            )
          : null,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getBorderColor(context, type),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    CustomSnackBarAction? action,
    bool showIcon = true,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
      action: action,
      showIcon: showIcon,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    CustomSnackBarAction? action,
    bool showIcon = true,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
      action: action,
      showIcon: showIcon,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    CustomSnackBarAction? action,
    bool showIcon = true,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
      action: action,
      showIcon: showIcon,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    CustomSnackBarAction? action,
    bool showIcon = true,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.info,
      duration: duration,
      action: action,
      showIcon: showIcon,
    );
  }

  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static Color _getBackgroundColor(BuildContext context, SnackBarType type) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    switch (type) {
      case SnackBarType.success:
        return isDarkMode 
            ? const Color(0xFF064E3B) 
            : const Color(0xFFDCFCE7);
      case SnackBarType.error:
        return isDarkMode 
            ? const Color(0xFF7F1D1D) 
            : const Color(0xFFFEE2E2);
      case SnackBarType.warning:
        return isDarkMode 
            ? const Color(0xFF92400E) 
            : const Color(0xFFFEF3C7);
      case SnackBarType.info:
        return isDarkMode 
            ? const Color(0xFF1E3A8A) 
            : const Color(0xFFDBEAFE);
    }
  }

  static Color _getBorderColor(BuildContext context, SnackBarType type) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    switch (type) {
      case SnackBarType.success:
        return isDarkMode 
            ? const Color(0xFF059669) 
            : const Color(0xFF10B981);
      case SnackBarType.error:
        return isDarkMode 
            ? const Color(0xFFDC2626) 
            : const Color(0xFFEF4444);
      case SnackBarType.warning:
        return isDarkMode 
            ? const Color(0xFFD97706) 
            : const Color(0xFFF59E0B);
      case SnackBarType.info:
        return isDarkMode 
            ? const Color(0xFF2563EB) 
            : const Color(0xFF3B82F6);
    }
  }

  static Color _getTextColor(BuildContext context, SnackBarType type) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    switch (type) {
      case SnackBarType.success:
        return isDarkMode 
            ? const Color(0xFFA7F3D0) 
            : const Color(0xFF065F46);
      case SnackBarType.error:
        return isDarkMode 
            ? const Color(0xFFFECACA) 
            : const Color(0xFF991B1B);
      case SnackBarType.warning:
        return isDarkMode 
            ? const Color(0xFFFDE68A) 
            : const Color(0xFF92400E);
      case SnackBarType.info:
        return isDarkMode 
            ? const Color(0xFFBFDBFE) 
            : const Color(0xFF1E40AF);
    }
  }

  static Color _getIconColor(BuildContext context, SnackBarType type) {
    return _getTextColor(context, type);
  }

  static Color _getIconBackgroundColor(BuildContext context, SnackBarType type) {
    return _getBorderColor(context, type).withOpacity(0.2);
  }

  static Color _getActionTextColor(BuildContext context, SnackBarType type) {
    return _getBorderColor(context, type);
  }

  static IconData _getIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle;
      case SnackBarType.error:
        return Icons.error;
      case SnackBarType.warning:
        return Icons.warning;
      case SnackBarType.info:
        return Icons.info;
    }
  }
}

enum SnackBarType { success, error, warning, info }

class CustomSnackBarAction {
  final String label;
  final VoidCallback onPressed;

  const CustomSnackBarAction({
    required this.label,
    required this.onPressed,
  });
}

class PersistentSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    required String actionLabel,
    required VoidCallback onActionPressed,
    SnackBarType type = SnackBarType.info,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: CustomSnackBar._getIconBackgroundColor(context, type),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CustomSnackBar._getIcon(type),
              size: 16,
              color: CustomSnackBar._getIconColor(context, type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: CustomSnackBar._getTextColor(context, type),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(days: 1), // Effectively persistent
      backgroundColor: CustomSnackBar._getBackgroundColor(context, type),
      action: SnackBarAction(
        label: actionLabel,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          onActionPressed();
        },
        textColor: CustomSnackBar._getActionTextColor(context, type),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: CustomSnackBar._getBorderColor(context, type),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}

class LoadingSnackBar {
  static void show({
    required BuildContext context,
    required String message,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(days: 1), // Persistent until dismissed
      backgroundColor: Theme.of(context).colorScheme.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}