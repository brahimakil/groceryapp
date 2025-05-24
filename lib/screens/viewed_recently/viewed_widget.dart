import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/inner_screens/product_details.dart';
import 'package:grocery_app/models/viewed_model.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:provider/provider.dart';
import '../../consts/firebase_consts.dart';
import '../../models/products_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/utils.dart';
import '../../widgets/text_widget.dart';

class ViewedRecentlyWidget extends StatefulWidget {
  const ViewedRecentlyWidget({Key? key}) : super(key: key);

  @override
  _ViewedRecentlyWidgetState createState() => _ViewedRecentlyWidgetState();
}

class _ViewedRecentlyWidgetState extends State<ViewedRecentlyWidget> {
  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductsProvider>(context);
    final viewedProdModel = Provider.of<ViewedProdModel>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final Color color = Utils(context).color;
    final Size size = Utils(context).getScreenSize;
    
    // Safe access with null handling for product
    ProductModel? getCurrProduct;
    try {
      getCurrProduct = productProvider.findProdById(viewedProdModel.productId);
    } catch (e) {
      // Return placeholder widget if product not found
      return const ListTile(
        title: Text("Product no longer available"),
        subtitle: Text("This product may have been removed"),
      );
    }
    
    // If product is still null after the try-catch, return early
    if (getCurrProduct == null) {
      return const ListTile(
        title: Text("Product not found"),
        subtitle: Text("This product may have been removed"),
      );
    }
    
    final double usedPrice = getCurrProduct.isOnSale
        ? getCurrProduct.salePrice
        : getCurrProduct.price;
        
    final bool isInCart = cartProvider.getCartItems.containsKey(getCurrProduct.id);
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          // Safe navigation with null check
          if (getCurrProduct != null) {
            Navigator.pushNamed(
              context,
              ProductDetails.routeName,
              // Fix the null-safety issue by using ?. to access id
              arguments: getCurrProduct?.id,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image section
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: size.width * 0.25,
                  height: size.width * 0.25,
                  child: _buildProductImage(getCurrProduct?.imageUrl ?? ''),
                ),
              ),
              const SizedBox(width: 12),
              
              // Product details section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getCurrProduct.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getCurrProduct.categoryName,
                      style: TextStyle(
                        color: color.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${usedPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Add to cart button
              Material(
                borderRadius: BorderRadius.circular(10),
                color: isInCart ? Colors.green.shade200 : Colors.green,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: isInCart ? null : () => _addToCart(context, getCurrProduct!, cartProvider),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      isInCart ? Icons.check : IconlyBold.plus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to build product image with error handling
  Widget _buildProductImage(String imageUrl) {
    return FancyShimmerImage(
      imageUrl: imageUrl,
      boxFit: BoxFit.cover,
      shimmerDuration: const Duration(milliseconds: 800),
      errorWidget: Image.asset(
        'assets/images/warning-sign.png',
        fit: BoxFit.contain,
      ),
    );
  }
  
  // Helper method to add product to cart
  Future<void> _addToCart(BuildContext context, ProductModel product, CartProvider cartProvider) async {
    final User? user = authInstance.currentUser;
    
    if (user == null) {
      GlobalMethods.errorDialog(
        subtitle: 'No user found. Please login first',
        context: context,
      );
      return;
    }
    
    try {
      setState(() {}); // Trigger rebuild for loading state if needed
      
      await GlobalMethods.addToCart(
        productId: product.id,
        quantity: 1,
        context: context,
      );
      
      await cartProvider.fetchCart();
      
      // Optional success indication
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.title} added to cart'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        GlobalMethods.errorDialog(
          subtitle: 'Failed to add to cart: $error',
          context: context,
        );
      }
    }
  }
}
