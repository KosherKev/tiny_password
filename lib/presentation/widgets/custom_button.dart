import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
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
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  // ignore: unused_field
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _resetAnimation();
  }

  void _onTapCancel() {
    _resetAnimation();
  }

  void _resetAnimation() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onPressed,
            child: Container(
              width: widget.width,
              height: widget.height ?? 56,
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                color: _getBackgroundColor(theme),
                border: widget.isOutlined ? _getBorder(theme) : null,
              ),
              child: _buildContent(theme),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.isOutlined) return Colors.transparent;
    
    if (widget.onPressed == null || widget.isLoading) {
      return theme.colorScheme.onSurface.withOpacity(0.12);
    }

    if (widget.isDestructive) {
      return theme.colorScheme.error;
    }

    return theme.colorScheme.primary;
  }

  Border? _getBorder(ThemeData theme) {
    if (!widget.isOutlined) return null;

    Color borderColor;
    if (widget.isDestructive) {
      borderColor = theme.colorScheme.error;
    } else {
      borderColor = theme.colorScheme.primary;
    }

    if (widget.onPressed == null || widget.isLoading) {
      borderColor = borderColor.withOpacity(0.38);
    }

    return Border.all(
      color: borderColor,
      width: 1,
    );
  }

  Widget _buildContent(ThemeData theme) {
    Color textColor = _getTextColor(theme);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 20,
              color: textColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            widget.text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Color _getTextColor(ThemeData theme) {
    if (widget.isOutlined) {
      if (widget.onPressed == null || widget.isLoading) {
        return theme.colorScheme.onSurface.withOpacity(0.38);
      }
      return widget.isDestructive 
          ? theme.colorScheme.error 
          : theme.colorScheme.primary;
    } else {
      if (widget.onPressed == null || widget.isLoading) {
        return theme.colorScheme.onSurface.withOpacity(0.38);
      }
      return widget.isDestructive 
          ? theme.colorScheme.onError 
          : theme.colorScheme.onPrimary;
    }
  }
}