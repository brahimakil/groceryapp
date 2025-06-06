import 'package:flutter/material.dart';
import '../consts/modern_theme.dart';

class ModernButton extends StatelessWidget {
  const ModernButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.gradient,
    this.width,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Gradient? gradient;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Button dimensions based on size
    double height;
    double fontSize;
    EdgeInsets padding;
    
    switch (size) {
      case ButtonSize.small:
        height = 36;
        fontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: ModernTheme.spaceM);
        break;
      case ButtonSize.medium:
        height = 44;
        fontSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: ModernTheme.spaceL);
        break;
      case ButtonSize.large:
        height = 52;
        fontSize = 18;
        padding = const EdgeInsets.symmetric(horizontal: ModernTheme.spaceXL);
        break;
    }
    
    // Colors based on variant
    Color backgroundColor;
    Color textColor;
    Color? borderColor;
    
    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = ModernTheme.primaryColor;
        textColor = Colors.white;
        break;
      case ButtonVariant.secondary:
        backgroundColor = ModernTheme.secondaryColor;
        textColor = Colors.white;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = ModernTheme.primaryColor;
        borderColor = ModernTheme.primaryColor;
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = theme.colorScheme.onSurface;
        break;
    }
    
    if (isDisabled) {
      backgroundColor = Colors.grey.shade300;
      textColor = Colors.grey.shade600;
      borderColor = null;
    }

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: ModernTheme.spaceS),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: ModernTheme.spaceS),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: variant == ButtonVariant.primary && !isDisabled ? [
            BoxShadow(
              color: ModernTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Material(
          color: gradient == null ? backgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
          child: InkWell(
            onTap: isDisabled || isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
            child: Container(
              padding: padding,
              child: Center(child: buttonChild),
            ),
          ),
        ),
      ),
    );
  }
}

enum ButtonVariant { primary, secondary, outline, ghost }
enum ButtonSize { small, medium, large } 