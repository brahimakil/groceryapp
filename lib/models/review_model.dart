import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewModel with ChangeNotifier {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String userEmail;
  final int rating; // 1-5 stars
  final String reviewText;
  final Timestamp createdAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
  });

  // Factory constructor to create a ReviewModel from a Firestore document
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ReviewModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userEmail: data['userEmail'] ?? '',
      rating: data['rating'] ?? 5,
      reviewText: data['reviewText'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Factory constructor to create a ReviewModel from JSON
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      userEmail: json['userEmail'] ?? '',
      rating: json['rating'] ?? 5,
      reviewText: json['reviewText'] ?? '',
      createdAt: json['createdAt'] != null 
          ? Timestamp.fromMillisecondsSinceEpoch(json['createdAt'])
          : Timestamp.now(),
    );
  }

  // Convert ReviewModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Convert ReviewModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': createdAt,
    };
  }
} 