import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductModel with ChangeNotifier {
  final String id;
  final String title;
  final String imageUrl; // Expecting Base64 string
  final String categoryId;
  final String categoryName;
  final String description;
  final double price;
  final double salePrice;
  final bool isOnSale;
  final bool isPiece;
  final String? calories; // Optional field
  final String? nutrients; // Optional field
  final Timestamp createdAt;

  ProductModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.price,
    required this.salePrice,
    required this.isOnSale,
    required this.isPiece,
    this.calories, // Optional
    this.nutrients, // Optional
    required this.createdAt,
  });

  // Factory constructor to create a ProductModel from a Firestore document
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Helper function to safely convert a value to String?
    String? _parseString(dynamic value) {
      if (value == null) {
        return null;
      }
      return value.toString(); // Convert numbers or other types to String
    }

    return ProductModel(
      id: doc.id, // Use document ID
      title: data['title'] ?? 'Untitled Product',
      imageUrl: data['imageUrl'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? 'Uncategorized',
      description: data['description'] ?? 'No description available.',
      price: _parseDouble(data['price'], defaultValue: 0.0),
      salePrice: _parseDouble(data['salePrice'], defaultValue: 0.0),
      isOnSale: data['isOnSale'] ?? false,
      isPiece: data['isPiece'] ?? false,
      // Safely parse calories and nutrients, converting numbers to strings
      calories: _parseString(data['calories']), 
      nutrients: _parseString(data['nutrients']), 
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Factory constructor to create a ProductModel from JSON (for local storage)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Product',
      imageUrl: json['imageUrl'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? 'Uncategorized',
      description: json['description'] ?? 'No description available.',
      price: _parseDouble(json['price'], defaultValue: 0.0),
      salePrice: _parseDouble(json['salePrice'], defaultValue: 0.0),
      isOnSale: json['isOnSale'] ?? false,
      isPiece: json['isPiece'] ?? false,
      calories: json['calories'],
      nutrients: json['nutrients'],
      createdAt: json['createdAt'] != null 
          ? Timestamp.fromMillisecondsSinceEpoch(json['createdAt'])
          : Timestamp.now(),
    );
  }

  // Convert ProductModel to JSON (for local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'isOnSale': isOnSale,
      'isPiece': isPiece,
      'calories': calories,
      'nutrients': nutrients,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Helper function to safely parse doubles
  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
