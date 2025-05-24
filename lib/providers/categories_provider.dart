import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/category_model.dart';

class CategoriesProvider with ChangeNotifier {
  List<CategoryModel> _categories = [];

  List<CategoryModel> get categories => _categories;

  Future<void> fetchCategories() async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name') // Optional: Order categories by name
          .get()
          .then((QuerySnapshot categoriesSnapshot) {
        _categories = []; // Clear previous list
        for (var element in categoriesSnapshot.docs) {
          try {
             // Use the factory constructor
            _categories.add(CategoryModel.fromJson(element));
          } catch (e) {
            print("Error parsing category ${element.id}: $e");
            // Optionally add a placeholder or skip the invalid category
          }
        }
        print("Fetched ${_categories.length} categories.");
        notifyListeners();
      });
    } catch (error) {
      print("Error fetching categories: $error");
      // Handle error appropriately, maybe set categories to empty list
      _categories = [];
      notifyListeners();
    }
  }
} 