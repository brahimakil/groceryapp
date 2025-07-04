import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showCount;

  const StarRatingWidget({
    Key? key,
    required this.rating,
    this.totalReviews = 0,
    this.size = 16.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.showCount = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Star display
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            if (index < rating.floor()) {
              // Full star
              return Icon(
                Icons.star,
                size: size,
                color: activeColor,
              );
            } else if (index < rating && rating % 1 != 0) {
              // Half star
              return Icon(
                Icons.star_half,
                size: size,
                color: activeColor,
              );
            } else {
              // Empty star
              return Icon(
                Icons.star_border,
                size: size,
                color: inactiveColor,
              );
            }
          }),
        ),
        
        // Rating count
        if (showCount && totalReviews > 0) ...[
          SizedBox(width: 4),
          Text(
            '($totalReviews)',
            style: TextStyle(
              fontSize: size * 0.8,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
} 