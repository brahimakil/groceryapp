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

class _OnSaleWidgetState extends State<OnSaleWidget> {
  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    final theme = Utils(context).getTheme;
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
    // Calculate proper image size
    double imageSize = isWeb ? 80 : screenWidth * 0.2;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.pushNamed(context, ProductDetails.routeName,
              arguments: productModel.id);
          viewedProdProvider.addProductToHistory(productId: productModel.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image and title in a row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with fixed size
                  SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Base64ImageWidget(
                        base64String: productModel.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: Container(
                          color: Colors.grey.shade300,
                        ),
                        errorWidget: Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image_not_supported, color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title and actions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          productModel.title,
                          style: TextStyle(
                            fontSize: isWeb ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Action buttons
                        Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _isInCart ? null : () async {
                                final User? user = authInstance.currentUser;
                                if (user == null) {
                                  GlobalMethods.errorDialog(
                                    subtitle: 'Please login first',
                                    context: context);
                                  return;
                                }
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
                                size: 20,
                                color: _isInCart ? Colors.green : color,
                              ),
                            ),
                            const SizedBox(width: 5),
                            HeartBTN(
                              productId: productModel.id,
                              isInWishlist: _isInWishlist,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Price
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: PriceWidget(
                  salePrice: productModel.salePrice,
                  price: productModel.price,
                  textPrice: '1',
                  isOnSale: productModel.isOnSale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
