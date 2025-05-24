import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/inner_screens/product_details.dart';
import 'package:grocery_app/models/wishlist_model.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../providers/products_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/utils.dart';
import '../../widgets/text_widget.dart';

class WishlistWidget extends StatelessWidget {
  const WishlistWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductsProvider>(context);
    final wishlistModel = Provider.of<WishlistModel>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    
    // Safe access to product - handle case when product might not exist
    ProductModel? getCurrProduct;
    try {
      getCurrProduct = productProvider.findProdById(wishlistModel.productId);
    } catch (e) {
      return const SizedBox.shrink(); // Return empty widget if product not found
    }
    
    if (getCurrProduct == null) {
      return const SizedBox.shrink(); // Return empty widget if product not found
    }
    
    final double usedPrice = getCurrProduct.isOnSale
        ? getCurrProduct.salePrice
        : getCurrProduct.price;
        
    final bool isInWishlist = wishlistProvider.getWishlistItems.containsKey(getCurrProduct.id);
    final Color color = Utils(context).color;
    final Size size = Utils(context).getScreenSize;
    
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context, 
              ProductDetails.routeName,
              arguments: wishlistModel.productId
            );
          },
          child: Container(
            height: size.height * 0.20,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    height: size.width * 0.25,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildProductImage(getCurrProduct.imageUrl),
                    ),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          getCurrProduct.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          getCurrProduct.categoryName,
                          style: TextStyle(
                            color: color.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '\$${usedPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () async {
                        await wishlistProvider.removeOneItem(
                          wishlistId: wishlistModel.id,
                          productId: wishlistModel.productId,
                        );
                      },
                      icon: Icon(
                        IconlyBold.delete,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context, 
                          ProductDetails.routeName,
                          arguments: wishlistModel.productId,
                        );
                      },
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: color,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to build product image with proper error handling
  Widget _buildProductImage(String imageUrl) {
    try {
      // Try to show image from base64 if the data is in that format
      if (imageUrl.contains(',') || imageUrl.length > 200) {
        String cleanBase64 = imageUrl;
        if (imageUrl.contains(',')) {
          cleanBase64 = imageUrl.split(',').last;
        }
        
        try {
          // Try to decode base64
          final imageBytes = base64Decode(base64.normalize(cleanBase64));
          return Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImageErrorPlaceholder();
            },
          );
        } catch (e) {
          return _buildImageErrorPlaceholder();
        }
      } else {
        // Assume it's a URL
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      }
    } catch (e) {
      return _buildImageErrorPlaceholder();
    }
  }
  
  Widget _buildImageErrorPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey.shade400,
        size: 30,
      ),
    );
  }
}
