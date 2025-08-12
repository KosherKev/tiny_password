import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isDestructive;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isDestructive = false,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isDestructive
        ? colorScheme.error
        : isOutlined
            ? Colors.transparent
            : colorScheme.primary;

    final foregroundColor = isDestructive
        ? colorScheme.onError
        : isOutlined
            ? colorScheme.primary
            : colorScheme.onPrimary;

    final borderSide = isOutlined
        ? BorderSide(
            color: isDestructive ? colorScheme.error : colorScheme.primary,
          )
        : null;

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: colorScheme.surfaceContainerHighest,
      disabledForegroundColor: colorScheme.onSurfaceVariant,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        side: borderSide ?? BorderSide.none,
      ),
      elevation: isOutlined ? 0 : null,
    );

    Widget child;
    if (isLoading) {
      child = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    } else {
      child = Text(text);
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isDestructive;
  final Color? color;
  final double? size;

  const CustomIconButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isDestructive = false,
    this.color,
    this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ??
        (isDestructive
            ? theme.colorScheme.error
            : theme.colorScheme.primary);

    return IconButton(
      icon: Icon(icon, color: iconColor, size: size),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 24,
    );
  }
}

class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool mini;
  final bool isLoading;

  const CustomFloatingActionButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.mini = false,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      mini: mini,
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon),
    );
  }
}