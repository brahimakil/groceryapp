import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:grocery_app/widgets/heart_btn.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:readmore/readmore.dart';

import '../consts/firebase_consts.dart';
import '../models/review_model.dart';
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../providers/viewed_prod_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/global_methods.dart';
import '../services/review_service.dart';
import '../services/utils.dart';
import '../widgets/text_widget.dart';
import '../widgets/price_widget.dart';
import '../widgets/add_review_dialog.dart';
import '../widgets/review_widget.dart';

class ProductDetails extends StatefulWidget {
  static const routeName = '/ProductDetails';

  const ProductDetails({Key? key}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final _quantityTextController = TextEditingController(text: '1');
  List<ReviewModel> _reviews = [];
  Map<String, dynamic> _ratingStats = {'averageRating': 0.0, 'totalReviews': 0};
  bool _isLoadingReviews = false;
  ReviewModel? _userReview;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _quantityTextController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productId = ModalRoute.of(context)!.settings.arguments as String;
    _loadReviews(productId);
  }

  Future<void> _loadReviews(String productId) async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      print('Loading reviews for product: $productId'); // Debug print
      
      final reviews = await ReviewService.getProductReviews(productId);
      final stats = await ReviewService.getProductRatingStats(productId);
      final userReview = await ReviewService.getUserReview(productId);

      print('Loaded ${reviews.length} reviews'); // Debug print
      print('Rating stats: $stats'); // Debug print
      print('User review: ${userReview?.reviewText ?? 'None'}'); // Debug print

      setState(() {
        _reviews = reviews;
        _ratingStats = stats;
        _userReview = userReview;
        _isLoadingReviews = false;
      });
    } catch (error) {
      print('Error loading reviews: $error');
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = Utils(context).getScreenSize;
    final Color color = Utils(context).color;

    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final productId = ModalRoute.of(context)!.settings.arguments as String;
    final productProvider = Provider.of<ProductsProvider>(context);
    final getCurrProduct = productProvider.findProdById(productId);

    double usedPrice = getCurrProduct?.isOnSale == true 
        ? getCurrProduct!.salePrice 
        : getCurrProduct!.price;
    double totalPrice = usedPrice * int.parse(_quantityTextController.text);
    bool? _isInCart = getCurrProduct?.id != null 
        ? cartProvider.getCartItems.containsKey(getCurrProduct!.id) 
        : false;

    bool? _isInWishlist = getCurrProduct?.id != null 
        ? wishlistProvider.getWishlistItems.containsKey(getCurrProduct!.id) 
        : false;

    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        viewedProdProvider.addProductToHistory(productId: productId);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
            leading: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  Navigator.canPop(context) ? Navigator.pop(context) : null,
              child: Icon(
                IconlyLight.arrowLeft2,
                color: color,
                size: 24,
              ),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor),
        body: Column(children: [
          Flexible(
            flex: 2,
            child: _buildProductImage(getCurrProduct?.imageUrl ?? '', context),
          ),
          Flexible(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, left: 30, right: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: TextWidget(
                            text: getCurrProduct?.title ?? 'Product',
                            color: color,
                            textSize: 25,
                            isTitle: true,
                          ),
                        ),
                        HeartBTN(
                          productId: getCurrProduct?.id ?? '',
                          isInWishlist: _isInWishlist,
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 5, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rating Section
                          _buildRatingSection(color, getCurrProduct?.title ?? ''),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                PriceWidget(
                                  salePrice: getCurrProduct?.salePrice ?? 0.0,
                                  price: getCurrProduct?.price ?? 0.0,
                                  textPrice: _quantityTextController.text,
                                  isOnSale: getCurrProduct?.isOnSale ?? false,
                                ),
                                const SizedBox(width: 8),
                                TextWidget(
                                  text: '/ item',
                                  color: color,
                                  textSize: 14,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (getCurrProduct?.calories != null && getCurrProduct!.calories!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Row(
                                children: [
                                   Icon(Icons.local_fire_department_outlined, color: Colors.orange, size: 20),
                                   const SizedBox(width: 5),
                                   TextWidget(
                                    text: 'Calories: ${getCurrProduct!.calories}',
                                    color: color,
                                    textSize: 16,
                                  ),
                                ],
                              ),
                            ),
                          if (getCurrProduct?.calories != null && getCurrProduct!.calories!.isNotEmpty)
                            const SizedBox(height: 8),
                          if (getCurrProduct?.nutrients != null && getCurrProduct!.nutrients!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                               child: Row(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Icon(Icons.spa_outlined, color: Colors.green, size: 20),
                                   const SizedBox(width: 5),
                                   Expanded(
                                     child: TextWidget(
                                      text: 'Nutrients: ${getCurrProduct!.nutrients}',
                                      color: color,
                                      textSize: 16,
                                                        ),
                                   ),
                                 ],
                               ),
                            ),
                           if (getCurrProduct?.nutrients != null && getCurrProduct!.nutrients!.isNotEmpty)
                             const SizedBox(height: 15),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                             child: ReadMoreText(
                               getCurrProduct?.description ?? '',
                               trimLines: 3,
                               colorClickableText: Colors.blue,
                               trimMode: TrimMode.Line,
                               trimCollapsedText: ' Show more',
                               trimExpandedText: ' Show less',
                               moreStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                               lessStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                               style: TextStyle(fontSize: 16, color: color),
                             ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Row(
                              children: [
                                quantityControl(
                                  fct: () {
                                    if (_quantityTextController.text == '1') {
                                      return;
                                    } else {
                                      setState(() {
                                        _quantityTextController.text =
                                            (int.parse(_quantityTextController.text) - 1)
                                                .toString();
                                      });
                                    }
                                  },
                                  icon: CupertinoIcons.minus,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  flex: 1,
                                  child: TextField(
                                    controller: _quantityTextController,
                                    key: const ValueKey('quantity'),
                                    keyboardType: TextInputType.number,
                                    maxLines: 1,
                                    decoration: const InputDecoration(
                                      border: UnderlineInputBorder(),
                                    ),
                                    textAlign: TextAlign.center,
                                    cursorColor: Colors.green,
                                    enabled: true,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        if (value.isEmpty) {
                                          _quantityTextController.text = '1';
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 5),
                                quantityControl(
                                  fct: () {
                                    setState(() {
                                      _quantityTextController.text =
                                          (int.parse(_quantityTextController.text) + 1)
                                              .toString();
                                    });
                                  },
                                  icon: CupertinoIcons.plus,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                          
                          // Reviews Section
                          _buildReviewsSection(color, getCurrProduct?.title ?? ''),
                          
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextWidget(
                                text: 'Total',
                                color: Colors.red.shade300,
                                textSize: 20,
                                isTitle: true,
                              ),
                              const SizedBox(height: 5),
                              FittedBox(
                                child: TextWidget(
                                  text: '\$${totalPrice.toStringAsFixed(2)}',
                                  color: color,
                                  textSize: 20,
                                  isTitle: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Material(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: _isInCart
                                  ? null
                                  : () async {
                                      final User? user =
                                          authInstance.currentUser;

                                      if (user == null) {
                                        GlobalMethods.errorDialog(
                                            subtitle:
                                                'No user found, Please login first',
                                            context: context);
                                        return;
                                      }
                                      await GlobalMethods.addToCart(
                                          productId: getCurrProduct?.id ?? '',
                                          quantity: int.parse(
                                              _quantityTextController.text),
                                          context: context);
                                      await cartProvider.fetchCart();
                                    },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: TextWidget(
                                      text:
                                          _isInCart ? 'In cart' : 'Add to cart',
                                      color: Colors.white,
                                      textSize: 18)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }

  Widget _buildRatingSection(Color color, String productName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                RatingBarIndicator(
                  rating: _ratingStats['averageRating']?.toDouble() ?? 0.0,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 20.0,
                  direction: Axis.horizontal,
                ),
                const SizedBox(width: 8),
                TextWidget(
                  text: '${_ratingStats['averageRating']?.toStringAsFixed(1) ?? '0.0'} (${_ratingStats['totalReviews']} reviews)',
                  color: color,
                  textSize: 14,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final User? user = authInstance.currentUser;
              if (user == null) {
                GlobalMethods.errorDialog(
                    subtitle: 'Please login to write a review',
                    context: context);
                return;
              }
              _showAddReviewDialog(productName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(_userReview != null ? 'Edit Review' : 'Write Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(Color color, String productName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: 'Customer Reviews',
            color: color,
            textSize: 20,
            isTitle: true,
          ),
          const SizedBox(height: 16),
          if (_isLoadingReviews)
            const Center(child: CircularProgressIndicator())
          else if (_reviews.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  TextWidget(
                    text: 'No reviews yet. Be the first to review this product!',
                    color: Colors.grey,
                    textSize: 16,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                final isCurrentUser = authInstance.currentUser?.uid == review.userId;
                
                return ReviewWidget(
                  review: review,
                  isCurrentUser: isCurrentUser,
                  onDelete: isCurrentUser ? () => _deleteReview(review.id) : null,
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddReviewDialog(String productName) {
    final productId = ModalRoute.of(context)!.settings.arguments as String;
    
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        productId: productId,
        productName: productName,
        onReviewAdded: () => _loadReviews(productId),
        existingReview: _userReview,
      ),
    );
  }

  void _deleteReview(String reviewId) async {
    final success = await ReviewService.deleteReview(reviewId);
    if (success) {
      final productId = ModalRoute.of(context)!.settings.arguments as String;
      _loadReviews(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget quantityControl(
      {required Function fct, required IconData icon, required Color color}) {
    return Flexible(
      flex: 2,
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: color,
        child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              fct();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                color: Colors.white,
                size: 25,
              ),
            )),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl, BuildContext context) {
    try {
      // Check if the image is likely a base64 string
      if (imageUrl.contains(',') || imageUrl.length > 200) {
        String cleanBase64 = imageUrl;
        if (imageUrl.contains(',')) {
          cleanBase64 = imageUrl.split(',').last;
        }
        
        try {
          // Try to decode base64
          cleanBase64 = base64.normalize(cleanBase64);
          final imageBytes = base64Decode(cleanBase64);
          return Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            height: MediaQuery.of(context).size.height * 0.4,
            errorBuilder: (ctx, error, stackTrace) {
              return _buildImageErrorPlaceholder(context);
            },
          );
        } catch (e) {
          print("Error decoding base64 image: $e");
          return _buildImageErrorPlaceholder(context);
        }
      } else {
        // Assume it's a URL
        return Image.network(
          imageUrl,
          fit: BoxFit.contain,
          height: MediaQuery.of(context).size.height * 0.4,
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
          errorBuilder: (ctx, error, stackTrace) {
            return _buildImageErrorPlaceholder(context);
          },
        );
      }
    } catch (e) {
      print("Error showing product image: $e");
      return _buildImageErrorPlaceholder(context);
    }
  }

  Widget _buildImageErrorPlaceholder(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            "Image not available",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
