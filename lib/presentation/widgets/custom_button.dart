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
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width,
              height: widget.height ?? 56,
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                gradient: _getGradient(),
                border: widget.isOutlined ? _getBorder() : null,
                boxShadow: _getShadow(),
              ),
              child: _buildContent(),
            ),
          ),
        );
      },
    );
  }

  LinearGradient? _getGradient() {
    if (widget.isOutlined) return null;
    
    if (widget.onPressed == null || widget.isLoading) {
      return LinearGradient(
        colors: [
          Colors.grey[600]!,
          Colors.grey[700]!,
        ],
      );
    }

    if (widget.isDestructive) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFef4444),
          Color(0xFFdc2626),
          Color(0xFFb91c1c),
        ],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFfbbf24), // Gold
        Color(0xFFf59e0b), // Darker gold
        Color(0xFFd97706), // Amber
      ],
    );
  }

  Border? _getBorder() {
    if (!widget.isOutlined) return null;

    Color borderColor;
    if (widget.isDestructive) {
      borderColor = const Color(0xFFef4444);
    } else {
      borderColor = const Color(0xFFfbbf24);
    }

    return Border.all(
      color: borderColor.withOpacity(widget.onPressed != null ? 1.0 : 0.5),
      width: 2,
    );
  }

  List<BoxShadow>? _getShadow() {
    if (widget.isOutlined || widget.onPressed == null || widget.isLoading) {
      return null;
    }

    Color shadowColor;
    if (widget.isDestructive) {
      shadowColor = const Color(0xFFef4444);
    } else {
      shadowColor = const Color(0xFFfbbf24);
    }

    return [
      BoxShadow(
        color: shadowColor.withOpacity(_isPressed ? 0.4 : 0.25),
        blurRadius: _isPressed ? 8 : 12,
        spreadRadius: _isPressed ? 1 : 2,
        offset: Offset(0, _isPressed ? 2 : 4),
      ),
    ];
  }

  Widget _buildContent() {
    Color textColor;
    
    if (widget.isOutlined) {
      if (widget.isDestructive) {
        textColor = const Color(0xFFef4444);
      } else {
        textColor = const Color(0xFFfbbf24);
      }
      if (widget.onPressed == null || widget.isLoading) {
        textColor = textColor.withOpacity(0.5);
      }
    } else {
      textColor = widget.isDestructive ? Colors.white : Colors.black;
      if (widget.onPressed == null || widget.isLoading) {
        textColor = Colors.grey[400]!;
      }
    }

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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}