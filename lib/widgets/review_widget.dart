import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/review_model.dart';
import '../services/utils.dart';
import '../widgets/text_widget.dart';

class ReviewWidget extends StatelessWidget {
  final ReviewModel review;
  final bool isCurrentUser;
  final VoidCallback? onDelete;

  const ReviewWidget({
    Key? key,
    required this.review,
    this.isCurrentUser = false,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: review.userName,
                        color: color,
                        textSize: 16,
                        isTitle: true,
                      ),
                      const SizedBox(height: 4),
                      RatingBarIndicator(
                        rating: review.rating.toDouble(),
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                        direction: Axis.horizontal,
                      ),
                    ],
                  ),
                ),
                if (isCurrentUser && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (review.reviewText.isNotEmpty)
              TextWidget(
                text: review.reviewText,
                color: color,
                textSize: 14,
                maxLines: 10,
              ),
            const SizedBox(height: 8),
            TextWidget(
              text: _formatDate(review.createdAt.toDate()),
              color: Colors.grey,
              textSize: 12,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 