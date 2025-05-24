import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class Base64ImageWidget extends StatelessWidget {
  final String? base64String;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget; // Widget to show on error
  final Widget? placeholder; // Widget to show while loading/decoding

  const Base64ImageWidget({
    Key? key,
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (base64String == null || base64String!.isEmpty) {
      return _buildErrorWidget(context, "Empty Base64 string");
    }

    try {
       // Attempt to decode the Base64 string
       // Remove potential data URI prefix if present (e.g., "data:image/png;base64,")
        String cleanBase64 = base64String!;
        if (base64String!.contains(',')) {
            cleanBase64 = base64String!.split(',').last;
        }

        // Add padding if needed
        cleanBase64 = base64.normalize(cleanBase64);

       final Uint8List imageBytes = base64Decode(cleanBase64);

      return Image.memory(
        imageBytes,
        width: width,
        height: height,
        fit: fit,
         // Fade in image
         frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
           if (wasSynchronouslyLoaded) {
             return child;
           }
           return AnimatedOpacity(
             opacity: frame == null ? 0 : 1,
             duration: const Duration(milliseconds: 300),
             curve: Curves.easeOut,
             child: child,
           );
         },
        errorBuilder: (context, error, stackTrace) {
          print("Error displaying Base64 image: $error");
          return _buildErrorWidget(context, "Display error");
        },
      );
    } catch (e) {
      print("Error decoding Base64 string: $e");
       // Handle decoding errors (invalid format, etc.)
      return _buildErrorWidget(context, "Decoding error");
    }
  }

   // Helper to build consistent error/placeholder widget
  Widget _buildErrorWidget(BuildContext context, String message) {
    return errorWidget ?? Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
         child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey[600], size: (width ?? height ?? 50) * 0.4),
              SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
         )
      ),
    );
  }
} 