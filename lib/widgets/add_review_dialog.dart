import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/review_service.dart';
import '../widgets/text_widget.dart';
import '../services/utils.dart';
import '../models/review_model.dart';

class AddReviewDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final VoidCallback onReviewAdded;
  final ReviewModel? existingReview;

  const AddReviewDialog({
    Key? key,
    required this.productId,
    required this.productName,
    required this.onReviewAdded,
    this.existingReview,
  }) : super(key: key);

  @override
  _AddReviewDialogState createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  int _rating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _reviewController.text = widget.existingReview!.reviewText;
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    final bool isEditing = widget.existingReview != null;
    
    return AlertDialog(
      title: TextWidget(
        text: '${isEditing ? 'Edit' : 'Rate'} ${widget.productName}',
        color: color,
        textSize: 18,
        isTitle: true,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: 'How would you rate this product?',
              color: color,
              textSize: 16,
            ),
            const SizedBox(height: 16),
            Center(
              child: RatingBar.builder(
                initialRating: _rating.toDouble(),
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  if (!_isLoading && !_isSubmitted) {
                    setState(() {
                      _rating = rating.toInt();
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'Write a review (optional)',
              color: color,
              textSize: 16,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              enabled: !_isLoading && !_isSubmitted,
              decoration: const InputDecoration(
                hintText: 'Share your experience with this product...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_isLoading || _isSubmitted) ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isLoading || _isSubmitted) ? null : _submitReview,
          child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Submit'),
        ),
      ],
    );
  }

  void _submitReview() async {
    if (_isLoading || _isSubmitted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isSubmitted = true;
    });

    try {
      final success = await ReviewService.addReview(
        productId: widget.productId,
        rating: _rating,
        reviewText: _reviewController.text.trim(),
        context: context,
      );

      if (success) {
        Navigator.of(context).pop();
        
        widget.onReviewAdded();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingReview != null 
                ? 'Review updated successfully!' 
                : 'Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isSubmitted = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingReview != null 
                ? 'Failed to update review. Please try again.' 
                : 'Failed to submit review. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isSubmitted = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 