import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:http/http.dart' as http;
import 'package:grocery_app/models/cart_model.dart';

class MealSuggestion {
  final String title;
  final String description;
  final List<String> requiredIngredients;
  final List<ProductModel> missingIngredients;

  MealSuggestion({
    required this.title,
    required this.description,
    required this.requiredIngredients,
    required this.missingIngredients,
  });
}

class MealSuggestionsProvider with ChangeNotifier {
  List<MealSuggestion> _suggestions = [];
  bool _isLoading = false;
  String _error = '';
  
  // Getters
  List<MealSuggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // Generate meal suggestions using the Gemini API
  Future<void> generateSuggestions({
    required List<ProductModel> allProducts,
    required Map<String, CartModel> cartItems,
    required ProductsProvider productsProvider,
  }) async {
    _isLoading = true;
    _error = '';
    _suggestions = [];
    notifyListeners();
    
    try {
      // Extract cart products from the productProvider based on cart item IDs
      List<ProductModel> cartProducts = [];
      cartItems.forEach((productId, cartModel) {
        final product = productsProvider.findProdById(productId);
        if (product != null) {
          cartProducts.add(product);
        }
      });
      
      if (cartProducts.isEmpty) {
        _error = 'Add some ingredients to your cart first';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Prepare data for API request
      final List<String> cartProductNames = cartProducts.map((p) => p.title).toList();
      final List<String> allProductNames = allProducts.map((p) => p.title).toList();
      
      // Make API call to Gemini
      final suggestions = await _callGeminiAPI(
        cartProductNames: cartProductNames,
        allProductNames: allProductNames,
      );
      
      if (suggestions.isNotEmpty) {
        // Process suggestions and find missing ingredients in the database
        _suggestions = _processSuggestions(
          suggestions, 
          cartProducts, 
          allProducts
        );
      } else {
        _error = 'Could not generate suggestions';
      }
    } catch (e) {
      _error = 'Error generating suggestions: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Process the response from Gemini API
  List<MealSuggestion> _processSuggestions(
    List<Map<String, dynamic>> suggestions,
    List<ProductModel> cartProducts,
    List<ProductModel> allProducts,
  ) {
    List<MealSuggestion> result = [];
    
    for (var suggestion in suggestions) {
      String title = suggestion['title'] ?? 'Recipe Suggestion';
      String description = suggestion['description'] ?? 'A delicious recipe idea.';
      List<String> requiredIngredients = [];
      
      // Handle potential null or various types in the response
      if (suggestion['ingredients'] != null) {
        if (suggestion['ingredients'] is List) {
          requiredIngredients = (suggestion['ingredients'] as List)
            .map((item) => item.toString())
            .toList();
        }
      }
      
      // Find missing ingredients from our product database
      List<ProductModel> missingIngredients = [];
      
      // For each required ingredient, check if it's already in the cart
      for (var ingredient in requiredIngredients) {
        bool isInCart = cartProducts.any(
          (product) => product.title.toLowerCase().contains(ingredient.toLowerCase())
        );
        
        if (!isInCart) {
          // Find matching products in our database
          final matchingProducts = allProducts.where(
            (product) => product.title.toLowerCase().contains(ingredient.toLowerCase())
          ).toList();
          
          // Add matching products to missing ingredients
          missingIngredients.addAll(matchingProducts);
        }
      }
      
      // Only add suggestions that have found missing ingredients in our database
      if (missingIngredients.isNotEmpty) {
        result.add(MealSuggestion(
          title: title,
          description: description,
          requiredIngredients: requiredIngredients,
          missingIngredients: missingIngredients,
        ));
      }
    }
    
    return result;
  }
  
  // Call the Gemini API
  Future<List<Map<String, dynamic>>> _callGeminiAPI({
    required List<String> cartProductNames,
    required List<String> allProductNames,
  }) async {
    const apiKey = 'AIzaSyB-1HSfGwyghl3nne_MhV_QvfnrSHMxA6k';
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
    
    // Build prompt with real data
    final prompt = '''
    Given a user's grocery cart with these items: ${cartProductNames.join(', ')}.
    
    Suggest 3 possible meal recipes that could be made using some or all of these ingredients,
    plus a few additional ingredients that the user might need to buy.
    
    The store has these products available: ${allProductNames.join(', ')}.
    
    Only suggest ingredients that are actually in this product list.
    
    For each recipe, provide:
    1. A title
    2. A brief description (1-2 sentences)
    3. A list of required ingredients (including ones they already have in their cart)
    
    Format the response as a JSON array with objects containing "title", "description", and "ingredients" (as an array of strings).
    ''';
    
    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topP': 0.95,
            'topK': 40,
            'maxOutputTokens': 1024,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          // Extract text from response
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          
          // Extract JSON from text (it might be wrapped in ```json or other markers)
          final jsonStart = text.indexOf('[');
          final jsonEnd = text.lastIndexOf(']') + 1;
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonText = text.substring(jsonStart, jsonEnd);
            final List<dynamic> suggestionsJson = jsonDecode(jsonText);
            return suggestionsJson.map((item) => item as Map<String, dynamic>).toList();
          }
          return [];
        } catch (e) {
          print('Error parsing Gemini response: $e');
          return [];
        }
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      return [];
    }
  }
} 