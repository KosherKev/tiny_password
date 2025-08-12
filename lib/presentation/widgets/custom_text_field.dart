import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final bool readOnly;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final bool? enabled;
  final Widget? prefix;
  final Widget? suffix;
  final EdgeInsetsGeometry? contentPadding;
  final FocusNode? focusNode;

  const CustomTextField({
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.enabled,
    this.prefix,
    this.suffix,
    this.contentPadding,
    this.focusNode,
    super.key,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with TickerProviderStateMixin {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode.removeListener(_handleFocusChange);
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      
      if (_isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1 + _focusAnimation.value * 0.05),
                Colors.white.withOpacity(0.05 + _focusAnimation.value * 0.03),
              ],
            ),
            border: Border.all(
              color: _getBorderColor(),
              width: 1 + _focusAnimation.value,
            ),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: const Color(0xFFfbbf24).withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            validator: widget.validator,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            enabled: widget.enabled,
            style: TextStyle(
              color: widget.enabled == false ? Colors.grey[400] : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              errorText: widget.errorText,
              prefixIcon: widget.prefix != null 
                ? Container(
                    margin: const EdgeInsets.only(left: 16, right: 12),
                    child: widget.prefix,
                  )
                : null,
              suffixIcon: _buildSuffixIcon(),
              contentPadding: widget.contentPadding ?? 
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              labelStyle: TextStyle(
                color: _isFocused 
                  ? const Color(0xFFfbbf24)
                  : Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFef4444),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBorderColor() {
    if (widget.errorText != null) {
      return const Color(0xFFef4444);
    }
    if (_isFocused) {
      return const Color(0xFFfbbf24);
    }
    return Colors.white.withOpacity(0.2);
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffix != null) return widget.suffix;

    List<Widget> actions = [];

    // Password visibility toggle
    if (widget.obscureText) {
      actions.add(
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              key: ValueKey(_obscureText),
              color: _isFocused
                  ? const Color(0xFFfbbf24)
                  : Colors.grey[400],
              size: 22,
            ),
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      );
    }

    // Clear button
    if (widget.controller != null && 
        widget.controller!.text.isNotEmpty && 
        !widget.obscureText &&
        !widget.readOnly) {
      actions.add(
        IconButton(
          icon: Icon(
            Icons.clear_rounded,
            color: Colors.grey[400],
            size: 22,
          ),
          onPressed: () {
            widget.controller?.clear();
            widget.onChanged?.call('');
          },
        ),
      );
    }

    if (actions.isEmpty) return null;

    if (actions.length == 1) {
      return actions.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }
}