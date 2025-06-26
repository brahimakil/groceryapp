import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/base64_image_widget.dart';
import 'package:grocery_app/widgets/heart_btn.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';
import '../consts/firebase_consts.dart';
import '../inner_screens/on_sale_screen.dart';
import '../inner_screens/product_details.dart';
import '../models/products_model.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/global_methods.dart';
import 'price_widget.dart';
import '../providers/viewed_prod_provider.dart';

class OnSaleWidget extends StatefulWidget {
  const OnSaleWidget({Key? key}) : super(key: key);

  @override
  State<OnSaleWidget> createState() => _OnSaleWidgetState();
}

class _OnSaleWidgetState extends State<OnSaleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productModel = Provider.of<ProductModel>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    bool? _isInCart = cartProvider.getCartItems.containsKey(productModel.id);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    bool? _isInWishlist = wishlistProvider.getWishlistItems.containsKey(productModel.id);
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context, listen: false);
    
    // Get screen width
    double screenWidth = MediaQuery.of(context).size.width;
    // Determine if we're on web
    bool isWeb = screenWidth > 800;
    bool isMobile = screenWidth <= 800;
    // Calculate proper image size
    double imageSize = isWeb ? 90 : screenWidth * 0.20; // Reduced from 0.22 to 0.20

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.all(isMobile ? 6 : 8), // Reduced margin on mobile
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20), // Smaller radius on mobile
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: isMobile ? 10 : 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: isDark 
                    ? Colors.grey.shade800.withOpacity(0.3)
                    : Colors.grey.shade200.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                onTap: () {
                  Navigator.pushNamed(context, ProductDetails.routeName,
                      arguments: productModel.id);
                  viewedProdProvider.addProductToHistory(productId: productModel.id);
                },
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0), // Reduced padding on mobile
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image and title in a row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image with enhanced styling
                          Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isDark
                                    ? [Colors.grey.shade800, Colors.grey.shade900]
                                    : [Colors.grey.shade50, Colors.grey.shade100],
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                                  child: Padding(
                                    padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
                                    child: Base64ImageWidget(
                                      base64String: productModel.imageUrl,
                                      fit: BoxFit.contain,
                                      placeholder: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              theme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.grey.shade400,
                                          size: isMobile ? 20 : 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Sale Badge
                                Positioned(
                                  top: 2,
                                  left: 2,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 4 : 6, 
                                      vertical: isMobile ? 1 : 2
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'SALE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isMobile ? 7 : 8,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isMobile ? 8 : 12),
                          // Title and actions
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Title
                                Text(
                                  productModel.title,
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : (isWeb ? 16 : 14),
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isMobile ? 6 : 8),
                                // Action buttons
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: _isInCart 
                                            ? Colors.green.shade600
                                            : theme.primaryColor,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_isInCart 
                                                ? Colors.green 
                                                : theme.primaryColor).withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(
                                          minWidth: isMobile ? 28 : 32,
                                          minHeight: isMobile ? 28 : 32,
                                        ),
                                        onPressed: _isInCart ? null : () async {
                                          final User? user = authInstance.currentUser;
                                          if (user == null) {
                                            GlobalMethods.errorDialog(
                                              subtitle: 'Please login first',
                                              context: context);
                                            return;
                                          }
                                          
                                          _animationController.forward().then((_) {
                                            _animationController.reverse();
                                          });
                                          
                                          try {
                                            await cartProvider.addProductToCart(
                                              productId: productModel.id,
                                              quantity: 1,
                                            );
                                          } catch (error) {
                                            GlobalMethods.errorDialog(
                                              subtitle: error.toString(), 
                                              context: context
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          _isInCart ? IconlyBold.bag2 : IconlyLight.bag2,
                                          size: isMobile ? 16 : 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 6 : 8),
                                    Container(
                                      width: isMobile ? 28 : 32,
                                      height: isMobile ? 28 : 32,
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: HeartBTN(
                                        productId: productModel.id,
                                        isInWishlist: _isInWishlist,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      // Price with enhanced styling - FIXED OVERFLOW HERE
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: [
                              // Price section - takes available space
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '\$${productModel.salePrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : (isWeb ? 18 : 16),
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 4 : 8),
                                    Flexible(
                                      child: Text(
                                        '\$${productModel.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: isMobile ? 10 : (isWeb ? 14 : 12),
                                          color: Colors.grey.shade500,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Discount badge - fixed width to prevent overflow
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * 0.3, // Max 30% of available width
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 6 : 8, 
                                  vertical: isMobile ? 2 : 4
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${((productModel.price - productModel.salePrice) / productModel.price * 100).round()}% OFF',
                                  style: TextStyle(
                                    fontSize: isMobile ? 8 : 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
