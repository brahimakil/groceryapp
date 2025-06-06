import 'package:flutter/material.dart';
import '../consts/modern_theme.dart';

class ModernCard extends StatelessWidget {
  const ModernCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation = 0,
    this.borderRadius,
    this.gradient,
    this.border,
    this.onTap,
    this.shadowColor,
    this.backgroundColor,
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Border? border;
  final VoidCallback? onTap;
  final Color? shadowColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Widget cardChild = Container(
      padding: padding ?? const EdgeInsets.all(ModernTheme.spaceM),
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? theme.cardColor) : null,
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(ModernTheme.radiusMedium),
        border: border ?? Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: elevation > 0 ? [
          BoxShadow(
            color: shadowColor ?? Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ] : null,
      ),
      child: child,
    );

    if (onTap != null) {
      cardChild = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(ModernTheme.radiusMedium),
          child: cardChild,
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardChild,
    );
  }
} 