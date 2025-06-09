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

class _CartScreenState extends State<CartScreen> {
  bool _isMealSuggestionsLoading = false;
  bool _showMealSuggestions = false;
  Map<String, bool> _expandedDescriptions = {};
  
  @override
  void initState() {
    super.initState();
    // Remove automatic API call on screen load
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _generateMealSuggestions();
    // });
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
    });
    
    // Get all products and properly cast them
    List<ProductModel> allProducts = [];
    for (var product in productsProvider.getProducts) {
      // Ensure each item is a ProductModel
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
                  // Add Recipe Suggestion Button - this replaces the toggle button
                  IconButton(
                    onPressed: () {
                      if (_showMealSuggestions && !_isMealSuggestionsLoading) {
                        // If already showing suggestions, hide them
                        setState(() {
                          _showMealSuggestions = false;
                        });
                      } else {
                        // If not showing suggestions or loading, generate new ones
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
            Text(
              mealSuggestionsProvider.error,
              style: const TextStyle(color: Colors.red),
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
    
    // Show suggestions
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.fastfood, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  "Recipe Suggestions",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const Spacer(),
                // Add a refresh button to generate new suggestions
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generateMealSuggestions,
                  tooltip: 'Refresh suggestions',
                ),
                // Add a close button to hide the suggestions panel
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showMealSuggestions = false;
                    });
                  },
                  tooltip: 'Hide suggestions',
                ),
              ],
            ),
          ),
          const Divider(),
          SizedBox(
            height: 220,
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
  }
  
  Widget _buildRecipeCard(MealSuggestion suggestion, CartProvider cartProvider) {
    final suggestionKey = suggestion.title; // Use title as unique key
    final isExpanded = _expandedDescriptions[suggestionKey] ?? false;
    
    return Container(
      width: 300, // Increased width slightly
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe title and description
          Padding(
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
                
                // Expandable description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedCrossFade(
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
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Missing ingredients section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (suggestion.missingIngredients.isNotEmpty) ...[
                    Text(
                      'Missing ingredients:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: suggestion.missingIngredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = suggestion.missingIngredients[index];
                        final isInCart = cartProvider.getCartItems.containsKey(ingredient.id);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                isInCart ? Icons.check_circle : Icons.add_circle_outline,
                                size: 16,
                                color: isInCart ? Colors.green : Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ingredient.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isInCart ? Colors.grey : null,
                                    decoration: isInCart ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isInCart)
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: const Size(50, 28),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
