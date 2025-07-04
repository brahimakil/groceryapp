import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/review_model.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection name for reviews
  static const String reviewsCollection = 'product_reviews';

  // Add a new review
  static Future<bool> addReview({
    required String productId,
    required int rating,
    required String reviewText,
    required BuildContext context,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user has already reviewed this product
      final existingReview = await _firestore
          .collection(reviewsCollection)
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existingReview.docs.isNotEmpty) {
        // Update existing review
        await _firestore
            .collection(reviewsCollection)
            .doc(existingReview.docs.first.id)
            .update({
          'rating': rating,
          'reviewText': reviewText,
          'createdAt': Timestamp.now(),
        });
      } else {
        // Create new review
        await _firestore.collection(reviewsCollection).add({
          'productId': productId,
          'userId': user.uid,
          'userName': user.displayName ?? 'Anonymous User',
          'userEmail': user.email ?? '',
          'rating': rating,
          'reviewText': reviewText,
          'createdAt': Timestamp.now(),
        });
      }

      // After successfully adding/updating the review, update product rating
      await updateProductRating(productId);

      return true;
    } catch (error) {
      print('Error adding review: $error');
      return false;
    }
  }

  // Get reviews for a specific product
  static Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      print('Fetching reviews for productId: $productId'); // Debug print
      
      final QuerySnapshot snapshot = await _firestore
          .collection(reviewsCollection)
          .where('productId', isEqualTo: productId)
          .get(); // Remove orderBy temporarily to avoid index issues

      print('Found ${snapshot.docs.length} reviews'); // Debug print

      final reviews = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
      
      // Sort manually instead of using orderBy
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return reviews;
    } catch (error) {
      print('Error fetching reviews: $error');
      return [];
    }
  }

  // Get average rating for a product
  static Future<Map<String, dynamic>> getProductRatingStats(String productId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(reviewsCollection)
          .where('productId', isEqualTo: productId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'averageRating': 0.0, 'totalReviews': 0};
      }

      double totalRating = 0;
      int totalReviews = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRating += (data['rating'] ?? 0).toDouble();
      }

      double averageRating = totalRating / totalReviews;

      return {
        'averageRating': averageRating,
        'totalReviews': totalReviews,
      };
    } catch (error) {
      print('Error fetching rating stats: $error');
      return {'averageRating': 0.0, 'totalReviews': 0};
    }
  }

  // Check if current user has reviewed this product
  static Future<ReviewModel?> getUserReview(String productId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final QuerySnapshot snapshot = await _firestore
          .collection(reviewsCollection)
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ReviewModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (error) {
      print('Error fetching user review: $error');
      return null;
    }
  }

  // Delete a review
  static Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(reviewsCollection).doc(reviewId).delete();
      return true;
    } catch (error) {
      print('Error deleting review: $error');
      return false;
    }
  }

  // Add this method to ReviewService
  static Stream<List<ReviewModel>> getProductReviewsStream(String productId) {
    return _firestore
        .collection(reviewsCollection)
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  // Add this method to calculate and update product ratings
  static Future<void> updateProductRating(String productId) async {
    try {
      final stats = await getProductRatingStats(productId);
      
      // Update the product document with rating data
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
        'averageRating': stats['averageRating'],
        'totalReviews': stats['totalReviews'],
      });
    } catch (error) {
      print('Error updating product rating: $error');
    }
  }
} 