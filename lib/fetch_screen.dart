import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:grocery_app/consts/contss.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/providers/wishlist_provider.dart';
import 'package:grocery_app/screens/btm_bar.dart';
import 'package:provider/provider.dart';

import 'providers/products_provider.dart';
import 'providers/categories_provider.dart';
import 'services/global_methods.dart';

class FetchScreen extends StatefulWidget {
  const FetchScreen({Key? key}) : super(key: key);

  @override
  State<FetchScreen> createState() => _FetchScreenState();
}

class _FetchScreenState extends State<FetchScreen> with TickerProviderStateMixin {
  List<String> images = Constss.authImagesPaths;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    _animationController.forward();
    
    // Increase timeout to MILLISECONDS (not microseconds)
    Future.delayed(const Duration(milliseconds: 1500), () async {
      try {
        // Get all necessary providers
        final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
        final categoriesProvider = Provider.of<CategoriesProvider>(context, listen: false);
        final User? user = authInstance.currentUser;
        
        // Wrap all data fetching in try-catch
        try {
           // Fetch products and categories concurrently
          await Future.wait([
             productsProvider.fetchProducts(),
             categoriesProvider.fetchCategories(),
          ]);

          // Fetch user-specific data if logged in
          if (user == null) {
            cartProvider.clearLocalCart();
            wishlistProvider.clearLocalWishlist();
          } else {
             // Fetch cart and wishlist concurrently
            await Future.wait([
              cartProvider.fetchCart(),
              wishlistProvider.fetchWishlist(),
            ]);
          }
        } catch (error) {
          print("Error during data fetching: $error");
          if (mounted) {
            GlobalMethods.errorDialog(subtitle: "Failed to load initial data: $error", context: context);
          }
        }
        
        // Navigate away after attempting fetches
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const BottomBarScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } catch (e) {
        print("Error in FetchScreen initialization: $e");
        if (mounted) {
          GlobalMethods.errorDialog(subtitle: "Initialization error: $e", context: context);
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (ctx) => const BottomBarScreen(),
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F0F0F),
                    const Color(0xFF1A1A1A),
                  ]
                : [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // App Title
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withOpacity(0.8),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      "Fresh Market",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    "Your premium grocery experience",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Modern Loading Indicator
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SpinKitThreeBounce(
                          color: theme.primaryColor,
                          size: 24.0,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Loading your fresh groceries...",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
