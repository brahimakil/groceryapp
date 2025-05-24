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

class _FeedsWidgetState extends State<FeedsWidget> {
  final _quantityTextController = TextEditingController();
  @override
  void initState() {
    _quantityTextController.text = '1';
    super.initState();
  }

  @override
  void dispose() {
    _quantityTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    final productModel = Provider.of<ProductModel>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    bool? _isInCart = cartProvider.getCartItems.containsKey(productModel.id);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    bool? _isInWishlist =
        wishlistProvider.getWishlistItems.containsKey(productModel.id);
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context, listen: false);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, ProductDetails.routeName,
              arguments: productModel.id);
          viewedProdProvider.addProductToHistory(productId: productModel.id);
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  height: MediaQuery.of(context).size.width > 800 ? 100 : size.width * 0.25,
                  width: MediaQuery.of(context).size.width > 800 ? 100 : size.width * 0.25,
                  child: Base64ImageWidget(
                    base64String: productModel.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: Container(
                      color: Colors.grey.shade300,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor)),
                    ),
                    errorWidget: Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_not_supported, color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                productModel.title,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 800 ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: PriceWidget(
                salePrice: productModel.salePrice,
                price: productModel.price,
                textPrice: _quantityTextController.text,
                isOnSale: productModel.isOnSale,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _isInCart
                        ? null
                        : () async {
                            final User? user = authInstance.currentUser;
                            if (user == null) {
                              GlobalMethods.errorDialog(
                                  subtitle: 'No user found, Please login first',
                                  context: context);
                              return;
                            }
                            await cartProvider.addProductToCart(
                                productId: productModel.id, quantity: 1);
                          },
                    icon: Icon(
                      _isInCart ? IconlyBold.bag2 : IconlyLight.bag2,
                      size: 22,
                      color: _isInCart ? Colors.green : color,
                    ),
                  ),
                  HeartBTN(
                    productId: productModel.id,
                    isInWishlist: _isInWishlist,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
