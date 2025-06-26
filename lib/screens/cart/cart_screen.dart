import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/screens/cart/cart_widget.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/global_methods.dart';
import '../../services/utils.dart';
import '../../widgets/empty_screen.dart';
import '../../providers/meal_suggestions_provider.dart';
import '../../models/products_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  bool _isMealSuggestionsLoading = false;
  bool _showMealSuggestions = false;
  bool _isSuggestionsMinimized = false; // New state for minimize/expand
  Map<String, bool> _expandedDescriptions = {};
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadSavedSuggestions();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Load saved suggestions from local storage
  Future<void> _loadSavedSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSuggestions = prefs.getString('meal_suggestions');
      final isMinimized = prefs.getBool('suggestions_minimized') ?? false;
      
      if (savedSuggestions != null) {
        final mealSuggestionsProvider = Provider.of<MealSuggestionsProvider>(context, listen: false);
        final suggestionsData = jsonDecode(savedSuggestions) as List;
        
        // Restore suggestions to provider
        mealSuggestionsProvider.restoreSuggestions(suggestionsData);
        
        setState(() {
          _showMealSuggestions = true;
          _isSuggestionsMinimized = isMinimized;
        });
        
        if (!isMinimized) {
          _animationController.forward();
        }
      }
    } catch (e) {
      print('Error loading saved suggestions: $e');
    }
  }
  
  // Save suggestions to local storage
  Future<void> _saveSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealSuggestionsProvider = Provider.of<MealSuggestionsProvider>(context, listen: false);
      
      if (mealSuggestionsProvider.suggestions.isNotEmpty) {
        final suggestionsJson = jsonEncode(
          mealSuggestionsProvider.suggestions.map((s) => s.toJson()).toList()
        );
        await prefs.setString('meal_suggestions', suggestionsJson);
        await prefs.setBool('suggestions_minimized', _isSuggestionsMinimized);
      }
    } catch (e) {
      print('Error saving suggestions: $e');
    }
  }
  
  // Clear saved suggestions from local storage
  Future<void> _clearSavedSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('meal_suggestions');
      await prefs.remove('suggestions_minimized');
    } catch (e) {
      print('Error clearing saved suggestions: $e');
    }
  }
  
  // Toggle minimize/expand suggestions
  void _toggleMinimize() {
    setState(() {
      _isSuggestionsMinimized = !_isSuggestionsMinimized;
    });
    
    if (_isSuggestionsMinimized) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    
    _saveSuggestions(); // Save the minimize state
  }
  
  // Generate meal suggestions based on cart items
  Future<void> _generateMealSuggestions() async {
    final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final mealSuggestionsProvider = Provider.of<MealSuggestionsProvider>(context, listen: false);
    
    // Only generate if cart is not empty
    if (cartProvider.getCartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add items to your cart to get recipe suggestions'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isMealSuggestionsLoading = true;
      _showMealSuggestions = true;
      _isSuggestionsMinimized = false;
    });
    
    _animationController.forward();
    
    // Get all products and properly cast them
    List<ProductModel> allProducts = [];
    for (var product in productsProvider.getProducts) {
      if (product is ProductModel) {
        allProducts.add(product);
      }
    }
    
    // Generate suggestions
    await mealSuggestionsProvider.generateSuggestions(
      allProducts: allProducts,
      cartItems: cartProvider.getCartItems,
      productsProvider: productsProvider,
    );
    
    setState(() {
      _isMealSuggestionsLoading = false;
    });
    
    // Save the new suggestions
    _saveSuggestions();
  }
  
  // Close suggestions completely
  void _closeSuggestions() {
    setState(() {
      _showMealSuggestions = false;
      _isSuggestionsMinimized = false;
    });
    
    _animationController.reset();
    
    // Clear suggestions from provider and storage
    final mealSuggestionsProvider = Provider.of<MealSuggestionsProvider>(context, listen: false);
    mealSuggestionsProvider.clearSuggestions();
    _clearSavedSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemsList = cartProvider.getCartItems.values.toList();
    final productsProvider = Provider.of<ProductsProvider>(context);
    final mealSuggestionsProvider = Provider.of<MealSuggestionsProvider>(context);
    
    return cartItemsList.isEmpty
        ? const EmptyScreen(
            title: 'Your cart is empty',
            subtitle: 'Add something and make me happy :)',
            buttonText: 'Shop now',
            imagePath: 'assets/images/cart.png',
          )
        : Scaffold(
            appBar: AppBar(
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                title: TextWidget(
                  text: 'Cart (${cartItemsList.length})',
                  color: color,
                  isTitle: true,
                  textSize: 22,
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      GlobalMethods.warningDialog(
                          title: 'Empty your cart?',
                          subtitle: 'Are you sure?',
                          fct: () async {
                            await cartProvider.clearOnlineCart();
                            cartProvider.clearLocalCart();
                          },
                          context: context);
                    },
                    icon: Icon(
                      IconlyBroken.delete,
                      color: color,
                    ),
                  ),
                  // Add Recipe Suggestion Button
                  IconButton(
                    onPressed: () {
                      if (_showMealSuggestions && !_isMealSuggestionsLoading) {
                        setState(() {
                          _showMealSuggestions = false;
                        });
                      } else {
                        setState(() {
                          _showMealSuggestions = true;
                        });
                        _generateMealSuggestions();
                      }
                    },
                    tooltip: 'Get Recipe Ideas',
                    icon: Icon(
                      _isMealSuggestionsLoading 
                          ? Icons.hourglass_empty 
                          : (_showMealSuggestions ? Icons.fastfood : Icons.fastfood_outlined),
                      color: _showMealSuggestions ? Theme.of(context).primaryColor : color,
                    ),
                  ),
                ]),
            body: Column(
              children: [
                // Show meal suggestions section if enabled
                if (_showMealSuggestions) _buildMealSuggestionsSection(context),
                
                _checkout(ctx: context),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItemsList.length,
                    itemBuilder: (ctx, index) {
                      return ChangeNotifierProvider.value(
                          value: cartItemsList[index],
                          child: CartWidget(
                            q: cartItemsList[index].quantity,
                          ));
                    },
                  ),
                ),
              ],
            ),
          );
  }
  
  Widget _buildMealSuggestionsSection(BuildContext context) {
    final mealSuggestionsProvider = Provider.of<MealSuggestionsProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    
    if (_isMealSuggestionsLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Our AI chef is finding recipe ideas based on your cart...")
            ],
          ),
        ),
      );
    }
    
    if (mealSuggestionsProvider.error.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Sorry, we couldn't generate recipe suggestions at the moment.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            TextButton(
              onPressed: _generateMealSuggestions,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (mealSuggestionsProvider.suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              const Text(
                "No recipe suggestions available.",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              TextButton(
                onPressed: _generateMealSuggestions,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show suggestions with minimize/expand functionality
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with all control buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.fastfood, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  "AI Recipe Suggestions",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const Spacer(),
                // Minimize/Expand button
                IconButton(
                  icon: AnimatedRotation(
                    turns: _isSuggestionsMinimized ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_up),
                  ),
                  onPressed: _toggleMinimize,
                  tooltip: _isSuggestionsMinimized ? 'Expand suggestions' : 'Minimize suggestions',
                ),
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generateMealSuggestions,
                  tooltip: 'Refresh suggestions',
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closeSuggestions,
                  tooltip: 'Close suggestions',
                ),
              ],
            ),
          ),
          
          // Animated content section
          AnimatedBuilder(
            animation: _heightAnimation,
            builder: (context, child) {
              return Container(
                height: _isSuggestionsMinimized ? 0 : 400 * _heightAnimation.value,
                child: _isSuggestionsMinimized 
                    ? null 
                    : Column(
                        children: [
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: mealSuggestionsProvider.suggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = mealSuggestionsProvider.suggestions[index];
                                return _buildRecipeCard(suggestion, cartProvider);
                              },
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecipeCard(MealSuggestion suggestion, CartProvider cartProvider) {
    final suggestionKey = suggestion.title; // Use title as unique key
    final isExpanded = _expandedDescriptions[suggestionKey] ?? false;
    
    return Container(
      width: 340, // Increased width to accommodate more content
      height: 400, // Keep fixed height but make content scrollable
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView( // Make the entire card content scrollable
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important: don't force full height
          children: [
            // Recipe title and description - Fixed height section
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Controlled expandable description with max height
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: isExpanded ? 100 : 40, // Reduced max height
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState: isExpanded 
                                ? CrossFadeState.showSecond 
                                : CrossFadeState.showFirst,
                            firstChild: Text(
                              suggestion.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondChild: Text(
                              suggestion.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                        
                        // Show "Read more" / "Read less" button only if text is long
                        if (suggestion.description.length > 80)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _expandedDescriptions[suggestionKey] = !isExpanded;
                                });
                              },
                              child: Text(
                                isExpanded ? 'Read less' : 'Read more',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Nutritional Information Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: Colors.green.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, 
                           size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${suggestion.nutritionalInfo.totalCalories.toInt()} cal',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.health_and_safety, 
                           size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Nutritious',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Nutritional breakdown in compact format
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildNutrientChip('Protein', suggestion.nutritionalInfo.protein, Colors.red),
                      _buildNutrientChip('Carbs', suggestion.nutritionalInfo.carbs, Colors.blue),
                      _buildNutrientChip('Fiber', suggestion.nutritionalInfo.fiber, Colors.green),
                    ],
                  ),
                  
                  // Health factors
                  if (suggestion.nutritionalInfo.healthFactors.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: suggestion.nutritionalInfo.healthFactors.map((factor) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            factor,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            // Preparation Steps Section (Expandable) - FIXED OVERFLOW HERE
            if (suggestion.preparationSteps.isNotEmpty)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Icon(Icons.restaurant_menu, 
                              size: 20, color: Theme.of(context).primaryColor),
                  title: const Text(
                    'Preparation Steps',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    // Removed ConstrainedBox to let content flow naturally
                    ListView.separated(
                      shrinkWrap: true, // Important: only take needed space
                      physics: const NeverScrollableScrollPhysics(), // Disable inner scrolling
                      padding: EdgeInsets.zero,
                      itemCount: suggestion.preparationSteps.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  suggestion.preparationSteps[index],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.3, // Slightly increased for readability
                                  ),
                                  // Removed maxLines to show full text
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            
            const Divider(height: 1),
            
            // Missing ingredients section - Now flexible
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Take only needed space
                children: [
                  if (suggestion.missingIngredients.isNotEmpty) ...[
                    Text(
                      'Missing ingredients:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Ingredients list - now shrinkWrap
                  suggestion.missingIngredients.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'All ingredients are in your cart! 🎉',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true, // Important: only take needed space
                          physics: const NeverScrollableScrollPhysics(), // Disable inner scrolling
                          padding: EdgeInsets.zero,
                          itemCount: suggestion.missingIngredients.length,
                          itemBuilder: (context, index) {
                            final ingredient = suggestion.missingIngredients[index];
                            final isInCart = cartProvider.getCartItems.containsKey(ingredient.id);
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isInCart 
                                    ? Colors.green.withOpacity(0.1)
                                    : Theme.of(context).cardColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isInCart 
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isInCart ? Icons.check_circle : Icons.add_circle_outline,
                                    size: 18,
                                    color: isInCart ? Colors.green : Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ingredient.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isInCart ? Colors.grey : null,
                                            decoration: isInCart ? TextDecoration.lineThrough : null,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        // Show calories if available
                                        if (ingredient.calories != null && ingredient.calories!.isNotEmpty)
                                          Text(
                                            '${ingredient.calories} cal',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (!isInCart) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          await cartProvider.addProductToCart(
                                            productId: ingredient.id,
                                            quantity: 1,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${ingredient.title} added to cart'),
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        } catch (error) {
                                          GlobalMethods.errorDialog(
                                            subtitle: error.toString(),
                                            context: context,
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: const Size(55, 32),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
            
            // Add some bottom padding to ensure scrolling works well
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build nutrient chips
  Widget _buildNutrientChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _checkout({required BuildContext ctx}) {
    final Color color = Utils(ctx).color;
    Size size = Utils(ctx).getScreenSize;
    final cartProvider = Provider.of<CartProvider>(ctx);
    final productProvider = Provider.of<ProductsProvider>(ctx);
    final ordersProvider = Provider.of<OrdersProvider>(ctx, listen: false);
    double total = 0.0;
    
    cartProvider.getCartItems.forEach((key, value) {
      final getCurrProduct = productProvider.findProdById(value.productId);
      if (getCurrProduct != null) {
        total += (getCurrProduct.isOnSale
                ? getCurrProduct.salePrice
                : getCurrProduct.price) *
            value.quantity;
      }
    });
    
    return SizedBox(
      width: double.infinity,
      height: size.height * 0.1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Material(
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                User? user = authInstance.currentUser;
                if (user == null) {
                  GlobalMethods.errorDialog(
                    subtitle: 'No user found, please login first',
                    context: ctx,
                  );
                  return;
                }
                
                if (cartProvider.getCartItems.isEmpty) {
                  GlobalMethods.errorDialog(
                    subtitle: 'Your cart is empty',
                    context: ctx,
                  );
                  return;
                }
                
                try {
                  // Show loading indicator
                  GlobalMethods.showLoading(ctx, 'Processing your order...');
                  
                  // Generate a single orderId for the entire order
                  final orderId = const Uuid().v4();
                  final orderTimestamp = Timestamp.now();
                  
                  // First, create the main order document
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .set({
                    'orderId': orderId,
                    'userId': user.uid,
                    'userName': user.displayName ?? user.email ?? 'Guest',
                    'orderDate': orderTimestamp,
                    'status': 'pending',
                    'totalPrice': total,
                    'productCount': cartProvider.getCartItems.length,
                  });
                  
                  // Then add each product as an order item
                  for (var entry in cartProvider.getCartItems.entries) {
                    final cartItem = entry.value;
                    final product = productProvider.findProdById(cartItem.productId);
                    
                    if (product != null) {
                      final itemId = const Uuid().v4();
                      final productPrice = product.isOnSale 
                          ? product.salePrice 
                          : product.price;
                      
                      // Create an order item for this product
                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(orderId)
                          .collection('items')
                          .doc(itemId)
                          .set({
                        'itemId': itemId,
                        'productId': product.id,
                        'title': product.title,
                        'price': productPrice * cartItem.quantity,
                        'singlePrice': productPrice,
                        'quantity': cartItem.quantity,
                        'imageUrl': product.imageUrl,
                      });
                    }
                  }
                  
                  // Close the loading dialog
                  Navigator.of(ctx, rootNavigator: true).pop();
                  
                  // Clear cart after successful order
                  await cartProvider.clearOnlineCart();
                  cartProvider.clearLocalCart();
                  
                  // Refresh orders list
                  await ordersProvider.fetchOrders();
                  
                  // Show success message
                  await Fluttertoast.showToast(
                    msg: "Your order has been placed",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                  );
                } catch (error) {
                  // Close loading dialog if open
                  Navigator.of(ctx, rootNavigator: true).pop();
                  
                  GlobalMethods.errorDialog(
                    subtitle: error.toString(),
                    context: ctx,
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextWidget(
                  text: 'Order Now',
                  textSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Spacer(),
          FittedBox(
            child: TextWidget(
              text: 'Total: \$${total.toStringAsFixed(2)}',
              color: color,
              textSize: 18,
              isTitle: true,
            ),
          ),
        ]),
      ),
    );
  }
}
