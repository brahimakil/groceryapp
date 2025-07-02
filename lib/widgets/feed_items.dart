import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/cart_provider.dart';
import 'package:grocery_app/widgets/base64_image_widget.dart';
import 'package:grocery_app/widgets/price_widget.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

import '../consts/firebase_consts.dart';
import '../inner_screens/on_sale_screen.dart';
import '../inner_screens/product_details.dart';
import '../providers/wishlist_provider.dart';
import '../services/global_methods.dart';
import '../services/utils.dart';
import 'heart_btn.dart';
import 'package:grocery_app/providers/viewed_prod_provider.dart';

class FeedsWidget extends StatefulWidget {
  const FeedsWidget({Key? key}) : super(key: key);

  @override
  State<FeedsWidget> createState() => _FeedsWidgetState();
}

class _FeedsWidgetState extends State<FeedsWidget> with SingleTickerProviderStateMixin {
  final _quantityTextController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    _quantityTextController.text = '1';
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    super.initState();
  }

  @override
  void dispose() {
    _quantityTextController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Size size = Utils(context).getScreenSize;
    final productModel = Provider.of<ProductModel>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    bool? _isInCart = cartProvider.getCartItems.containsKey(productModel.id);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    bool? _isInWishlist = wishlistProvider.getWishlistItems.containsKey(productModel.id);
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context, listen: false);

    // Dynamic sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 800;
    final isMobile = screenWidth <= 800;
    
    // Responsive dimensions
    final borderRadius = isTablet ? 20.0 : 16.0;
    final cardMargin = isTablet ? 8.0 : 4.0;
    final imagePadding = isTablet ? 16.0 : 12.0;
    final contentPadding = isTablet ? 16.0 : 10.0;
    
    // Responsive font sizes
    final titleFontSize = isTablet ? 16.0 : 13.0;
    final priceFontSize = isTablet ? 18.0 : 15.0;
    final buttonFontSize = isTablet ? 14.0 : 11.0;

    return Container(
      margin: EdgeInsets.all(cardMargin),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: isTablet ? 15 : 10,
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
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, ProductDetails.routeName,
                arguments: productModel.id);
            viewedProdProvider.addProductToHistory(productId: productModel.id);
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate available height and distribute it intelligently
              final availableHeight = constraints.maxHeight - (cardMargin * 2);
              final buttonHeight = isTablet ? 36.0 : 32.0;
              final minContentHeight = buttonHeight + (contentPadding * 2) + 60; // Button + padding + min text space
              final imageHeight = availableHeight - minContentHeight;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section with calculated height
                  SizedBox(
                    height: imageHeight > 80 ? imageHeight : 80, // Minimum image height
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(borderRadius),
                              topRight: Radius.circular(borderRadius),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isDark
                                  ? [Colors.grey.shade800, Colors.grey.shade900]
                                  : [Colors.grey.shade50, Colors.grey.shade100],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(borderRadius),
                              topRight: Radius.circular(borderRadius),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(imagePadding),
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
                                    size: isTablet ? 32 : 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Sale Badge
                        if (productModel.isOnSale)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 6 : 4, 
                                vertical: isTablet ? 3 : 2
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                                ),
                                borderRadius: BorderRadius.circular(8),
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
                                  fontSize: isTablet ? 9 : 7,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        
                        // Wishlist Button
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: isTablet ? 32 : 28,
                            height: isTablet ? 32 : 28,
                            decoration: BoxDecoration(
                              color: theme.cardColor.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: HeartBTN(
                              productId: productModel.id,
                              isInWishlist: _isInWishlist,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Product Info Section with calculated remaining height
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(contentPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Title - Takes available space
                          Expanded(
                            child: Text(
                              productModel.title,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w600,
                                color: color,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 6 : 4),
                          
                          // Price Section - Fixed height to prevent overflow
                          SizedBox(
                            height: priceFontSize + 4,
                            child: Row(
                              children: [
                                if (productModel.isOnSale) ...[
                                  Flexible(
                                    child: Text(
                                      '\$${productModel.salePrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: priceFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '\$${productModel.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: priceFontSize - 2,
                                        color: Colors.grey.shade500,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ] else
                                  Flexible(
                                    child: Text(
                                      '\$${productModel.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: priceFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 8 : 6),
                          
                          // Add to Cart Button - with improved state handling
                          SizedBox(
                            width: double.infinity,
                            height: buttonHeight,
                            child: ElevatedButton(
                              onPressed: _isInCart ? null : () async {
                                final User? user = authInstance.currentUser;
                                if (user == null) {
                                  GlobalMethods.errorDialog(
                                      subtitle: 'Please login to add items to cart',
                                      context: context);
                                  return;
                                }
                                
                                HapticFeedback.mediumImpact();
                                // Only use scale animation for button press feedback
                                _animationController.forward().then((_) {
                                  _animationController.reverse();
                                });
                                
                                try {
                                  await cartProvider.addProductToCart(
                                      productId: productModel.id, quantity: 1);
                                  
                                  // Show success feedback
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${productModel.title} added to cart'),
                                        duration: const Duration(milliseconds: 1200),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
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
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isInCart 
                                    ? Colors.green.shade600
                                    : theme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                ),
                                shadowColor: _isInCart 
                                    ? Colors.green.withOpacity(0.3)
                                    : theme.primaryColor.withOpacity(0.3),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Row(
                                  key: ValueKey(_isInCart),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isInCart ? IconlyBold.bag2 : IconlyLight.bag2,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 6 : 4),
                                    Flexible(
                                      child: Text(
                                        _isInCart ? 'In Cart' : 'Add to Cart',
                                        style: TextStyle(
                                          fontSize: buttonFontSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
