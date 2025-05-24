import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryModel with ChangeNotifier {
  final String id;
  final String name;
  final String imageUrl; // Expecting Base64 string
  final Timestamp createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id, // Use document ID as the category ID
      name: data['name'] ?? 'Unknown Category',
      imageUrl: data['imageUrl'] ?? '', // Provide default empty string
      createdAt: data['createdAt'] ?? Timestamp.now(), // Provide default
    );
  }
} 