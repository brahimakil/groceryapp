import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:http/http.dart' as http;
import 'package:grocery_app/models/cart_model.dart';

class NutritionalInfo {
  final double totalCalories;
  final String protein;
  final String carbs;
  final String fat;
  final String fiber;
  final List<String> healthFactors;

  NutritionalInfo({
    required this.totalCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.healthFactors,
  });
}

class MealSuggestion {
  final String title;
  final String description;
  final List<String> requiredIngredients;
  final List<ProductModel> missingIngredients;
  final List<String> preparationSteps;
  final NutritionalInfo nutritionalInfo;

  MealSuggestion({
    required this.title,
    required this.description,
    required this.requiredIngredients,
    required this.missingIngredients,
    required this.preparationSteps,
    required this.nutritionalInfo,
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
      
      // Prepare data for API request including nutritional data
      final List<Map<String, dynamic>> cartProductData = cartProducts.map((p) => {
        'name': p.title,
        'calories': p.calories ?? '0',
        'nutrients': p.nutrients ?? '',
        'category': p.categoryName,
      }).toList();
      
      final List<Map<String, dynamic>> allProductData = allProducts.map((p) => {
        'name': p.title,
        'calories': p.calories ?? '0',
        'nutrients': p.nutrients ?? '',
        'category': p.categoryName,
      }).toList();
      
      // Make API call to Gemini
      final suggestions = await _callGeminiAPI(
        cartProductData: cartProductData,
        allProductData: allProductData,
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
  
  // Calculate nutritional information for a meal
  NutritionalInfo _calculateNutritionalInfo(
    List<String> requiredIngredients,
    List<ProductModel> cartProducts,
    List<ProductModel> allProducts,
  ) {
    double totalCalories = 0;
    List<String> proteinSources = [];
    List<String> carbSources = [];
    List<String> fatSources = [];
    List<String> fiberSources = [];
    List<String> healthFactors = [];
    
    // Get all products that are part of this meal
    List<ProductModel> mealProducts = [];
    
    for (var ingredient in requiredIngredients) {
      // Check if it's in cart
      var cartProduct = cartProducts.where(
        (product) => product.title.toLowerCase().contains(ingredient.toLowerCase())
      ).toList();
      
      if (cartProduct.isNotEmpty) {
        mealProducts.addAll(cartProduct);
      } else {
        // Check if it's in available products
        var availableProduct = allProducts.where(
          (product) => product.title.toLowerCase().contains(ingredient.toLowerCase())
        ).toList();
        
        if (availableProduct.isNotEmpty) {
          mealProducts.add(availableProduct.first);
        }
      }
    }
    
    // Calculate totals
    for (var product in mealProducts) {
      // Add calories
      if (product.calories != null && product.calories!.isNotEmpty) {
        totalCalories += double.tryParse(product.calories!) ?? 0;
      }
      
      // Analyze nutrients
      if (product.nutrients != null && product.nutrients!.isNotEmpty) {
        String nutrients = product.nutrients!.toLowerCase();
        
        if (nutrients.contains('protein')) proteinSources.add(product.title);
        if (nutrients.contains('carb') || nutrients.contains('starch')) carbSources.add(product.title);
        if (nutrients.contains('fat') || nutrients.contains('oil')) fatSources.add(product.title);
        if (nutrients.contains('fiber')) fiberSources.add(product.title);
        
        // Health factors based on categories and nutrients
        if (product.categoryName.toLowerCase().contains('fruit')) {
          healthFactors.add('Rich in vitamins');
        }
        if (product.categoryName.toLowerCase().contains('vegetable')) {
          healthFactors.add('High in antioxidants');
        }
        if (nutrients.contains('omega')) {
          healthFactors.add('Heart-healthy fats');
        }
        if (nutrients.contains('calcium')) {
          healthFactors.add('Bone health');
        }
      }
    }
    
    // Remove duplicates
    healthFactors = healthFactors.toSet().toList();
    
    return NutritionalInfo(
      totalCalories: totalCalories,
      protein: proteinSources.isNotEmpty 
          ? '${proteinSources.length} sources (${proteinSources.take(2).join(', ')}${proteinSources.length > 2 ? '...' : ''})'
          : 'Low protein',
      carbs: carbSources.isNotEmpty 
          ? '${carbSources.length} sources (${carbSources.take(2).join(', ')}${carbSources.length > 2 ? '...' : ''})'
          : 'Low carbs',
      fat: fatSources.isNotEmpty 
          ? '${fatSources.length} sources (${fatSources.take(2).join(', ')}${fatSources.length > 2 ? '...' : ''})'
          : 'Low fat',
      fiber: fiberSources.isNotEmpty 
          ? '${fiberSources.length} sources (${fiberSources.take(2).join(', ')}${fiberSources.length > 2 ? '...' : ''})'
          : 'Low fiber',
      healthFactors: healthFactors.take(3).toList(), // Limit to top 3
    );
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
      List<String> preparationSteps = [];
      
      // Handle ingredients
      if (suggestion['ingredients'] != null) {
        if (suggestion['ingredients'] is List) {
          requiredIngredients = (suggestion['ingredients'] as List)
            .map((item) => item.toString())
            .toList();
        }
      }
      
      // Handle preparation steps
      if (suggestion['steps'] != null) {
        if (suggestion['steps'] is List) {
          preparationSteps = (suggestion['steps'] as List)
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
          
          // Add matching products to missing ingredients (avoid duplicates)
          for (var product in matchingProducts) {
            if (!missingIngredients.any((existing) => existing.id == product.id)) {
              missingIngredients.add(product);
            }
          }
        }
      }
      
      // Calculate nutritional information
      final nutritionalInfo = _calculateNutritionalInfo(
        requiredIngredients,
        cartProducts,
        allProducts,
      );
      
      // Add suggestion (even if no missing ingredients, for complete recipes)
      result.add(MealSuggestion(
        title: title,
        description: description,
        requiredIngredients: requiredIngredients,
        missingIngredients: missingIngredients,
        preparationSteps: preparationSteps,
        nutritionalInfo: nutritionalInfo,
      ));
    }
    
    return result;
  }
  
  // Call the Gemini API with enhanced prompt
  Future<List<Map<String, dynamic>>> _callGeminiAPI({
    required List<Map<String, dynamic>> cartProductData,
    required List<Map<String, dynamic>> allProductData,
  }) async {
    const apiKey = 'AIzaSyB-1HSfGwyghl3nne_MhV_QvfnrSHMxA6k';
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
    
    // Build enhanced prompt with nutritional data and steps request
    final prompt = '''
    Given a user's grocery cart with these items and their nutritional info: 
    ${cartProductData.map((p) => '${p['name']} (${p['calories']} cal, nutrients: ${p['nutrients']})').join(', ')}.
    
    Available products in store: 
    ${allProductData.map((p) => '${p['name']} (${p['calories']} cal, nutrients: ${p['nutrients']})').join(', ')}.
    
    Please suggest 3 healthy meal recipes that could be made using some or all of the cart ingredients,
    plus a few additional ingredients from the available products.
    
    For each recipe, provide:
    1. A creative title
    2. A brief description (1-2 sentences) highlighting health benefits
    3. A list of required ingredients (including ones they already have)
    4. Step-by-step preparation instructions (numbered steps, keep each step concise)
    
    Focus on balanced nutrition and consider the calorie and nutrient content of ingredients.
    Make the recipes practical and achievable for home cooking.
    
    Format the response as a JSON array with objects containing:
    - "title": string
    - "description": string  
    - "ingredients": array of strings
    - "steps": array of strings (numbered preparation steps)
    
    Example format:
    [
      {
        "title": "Healthy Veggie Stir Fry",
        "description": "A nutritious and colorful meal packed with vitamins and fiber.",
        "ingredients": ["broccoli", "carrots", "olive oil", "garlic"],
        "steps": ["1. Heat oil in pan", "2. Add garlic and sauté", "3. Add vegetables and stir-fry", "4. Season and serve"]
      }
    ]
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
            'maxOutputTokens': 2048, // Increased for more detailed responses
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