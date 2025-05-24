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

class _FetchScreenState extends State<FetchScreen> {
  List<String> images = Constss.authImagesPaths;
  bool _isLoading = true;
  
  @override
  void initState() {
    // images.shuffle(); // Keep commented out
    
    // Increase timeout to MILLISECONDS (not microseconds)
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // Get all necessary providers
        final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
        final categoriesProvider = Provider.of<CategoriesProvider>(context, listen: false); // Get CategoriesProvider
        final User? user = authInstance.currentUser;
        
        // Wrap all data fetching in try-catch
        try {
           // Fetch products and categories concurrently
          await Future.wait([
             productsProvider.fetchProducts(),
             categoriesProvider.fetchCategories(), // Fetch categories
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
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (ctx) => const BottomBarScreen(),
          ));
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Use a solid color background instead of images
          Container(
            color: Colors.white,
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Grocery App",
                    style: TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Loading your shopping experience...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Show a loading spinner
          Center(
            child: SpinKitFadingFour(
              color: Colors.green.shade700,
              size: 50.0,
            ),
          ),
        ],
      ),
    );
  }
}
