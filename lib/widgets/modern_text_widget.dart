import 'package:flutter/material.dart';

class ModernTextWidget extends StatelessWidget {
  const ModernTextWidget({
    Key? key,
    required this.text,
    this.style,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.isTitle = false,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.gradient,
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool isTitle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    TextStyle textStyle = style ?? 
      (isTitle ? theme.textTheme.titleLarge! : theme.textTheme.bodyMedium!);
    
    if (color != null) {
      textStyle = textStyle.copyWith(color: color);
    }
    
    if (fontSize != null) {
      textStyle = textStyle.copyWith(fontSize: fontSize);
    }
    
    if (fontWeight != null) {
      textStyle = textStyle.copyWith(fontWeight: fontWeight);
    }

    if (gradient != null) {
      return ShaderMask(
        shaderCallback: (bounds) => gradient!.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
        child: Text(
          text,
          style: textStyle.copyWith(color: Colors.white),
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        ),
      );
    }

    return Text(
      text,
      style: textStyle,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
} 