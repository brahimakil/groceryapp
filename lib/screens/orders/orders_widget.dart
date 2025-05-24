import 'package:flutter/material.dart';
import 'package:grocery_app/inner_screens/product_details.dart';
import 'package:grocery_app/models/orders_model.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/base64_image_widget.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

class OrderWidget extends StatelessWidget {
  const OrderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ordersModel = Provider.of<OrderModel>(context);
    final Color color = Utils(context).color;
    final size = Utils(context).getScreenSize;
    final productsProvider = Provider.of<ProductsProvider>(context);
    
    // Get product if it exists
    ProductModel? getCurrProduct;
    if (ordersModel.productId.isNotEmpty) {
      getCurrProduct = productsProvider.findProdById(ordersModel.productId);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Product image
          SizedBox(
            width: size.width * 0.15,
            height: size.width * 0.15,
            child: _buildProductImage(ordersModel.imageUrl, size),
          ),
          const SizedBox(width: 10),
          
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getCurrProduct?.title ?? 'Product no longer available',
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${ordersModel.quantityAsInt}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Price
          Text(
            '\$${ordersModel.priceAsDouble.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductImage(String imageUrl, Size size) {
    if (imageUrl.isEmpty) {
      return Container(
        width: size.width * 0.2,
        height: size.width * 0.2,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.shopping_bag, color: Colors.grey),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size.width * 0.2,
        height: size.width * 0.2,
        child: Base64ImageWidget(
          base64String: imageUrl,
          fit: BoxFit.cover,
          width: size.width * 0.2,
          height: size.width * 0.2,
          placeholder: Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: Container(
            color: Colors.grey.shade200,
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey.shade400,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
