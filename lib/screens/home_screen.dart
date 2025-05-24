import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/inner_screens/feeds_screen.dart';
import 'package:grocery_app/inner_screens/on_sale_screen.dart';
import 'package:grocery_app/providers/dark_theme_provider.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../consts/contss.dart';
import '../models/products_model.dart';
import '../providers/products_provider.dart';
import '../providers/categories_provider.dart';
import '../models/category_model.dart';
import '../services/global_methods.dart';
import '../widgets/feed_items.dart';
import '../widgets/on_sale_widget.dart';
import '../widgets/base64_image_widget.dart';
import '../inner_screens/cat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch products after the first frame if they are missing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductsProvider>(context, listen: false);
      if (mounted && productProvider.getProducts.isEmpty) {
        print("HomeScreen initState: Products empty, attempting fetch...");
        // Don't await here, let it run in the background
        productProvider.fetchProducts().catchError((error) {
           print("Error fetching products from HomeScreen initState: $error");
           // Optionally show a snackbar or message to the user
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: TextWidget(text: 'Could not reload products.', color: Colors.white, textSize: 14), backgroundColor: Colors.red),
             );
           }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Utils utils = Utils(context);
    final themeState = utils.getTheme;
    final Color color = Utils(context).color;
    Size size = utils.getScreenSize;
    final productProviders = Provider.of<ProductsProvider>(context);
    final categoriesProvider = Provider.of<CategoriesProvider>(context);
    List<ProductModel> allProducts = productProviders.getProducts;
    List<ProductModel> productsOnSale = productProviders.getOnSaleProducts;
    List<CategoryModel> categories = categoriesProvider.categories;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: size.height * 0.30,
              child: Swiper(
                itemBuilder: (BuildContext context, int index) {
                  return Image.network(
                    Constss.offerImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: Icon(Icons.error)),
                  );
                },
                autoplay: true,
                itemCount: Constss.offerImages.length,
                pagination: const SwiperPagination(
                    alignment: Alignment.bottomCenter,
                    builder: DotSwiperPaginationBuilder(
                        color: Colors.white70, activeColor: Colors.redAccent)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidget(
                    text: 'On Sale',
                    color: Colors.redAccent,
                    textSize: 20,
                    isTitle: true,
                  ),
                  TextButton(
                    onPressed: () {
                      GlobalMethods.navigateTo(
                          ctx: context, routeName: OnSaleScreen.routeName);
                    },
                    child: TextWidget(
                      text: 'View all',
                      maxLines: 1,
                      color: Colors.blue,
                      textSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.width > 800 ? 160 : size.height * 0.22,
              child: ListView.builder(
                itemCount: productsOnSale.length < 10 ? productsOnSale.length : 10,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemBuilder: (ctx, index) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width > 800 ? 300 : size.width * 0.5,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChangeNotifierProvider.value(
                        value: productsOnSale[index],
                        child: const OnSaleWidget(),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 8.0, right: 8.0, bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidget(
                    text: 'Our products',
                    color: color,
                    textSize: 20,
                    isTitle: true,
                  ),
                  TextButton(
                    onPressed: () {
                      GlobalMethods.navigateTo(
                          ctx: context, routeName: FeedsScreen.routeName);
                    },
                    child: TextWidget(
                      text: 'Browse all',
                      maxLines: 1,
                      color: Colors.blue,
                      textSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            if (allProducts.isEmpty) 
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(child: TextWidget(text: "No products found.", color: color, textSize: 18)),
              )
            else 
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 :
                                (MediaQuery.of(context).size.width > 800 ? 4 : 2),
                  childAspectRatio: MediaQuery.of(context).size.width > 800 ? 0.9 : 0.68,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                padding: const EdgeInsets.all(10),
                itemCount: allProducts.length < 8 ? allProducts.length : 8,
                itemBuilder: (ctx, index) {
                  return ChangeNotifierProvider.value(
                    value: allProducts[index],
                    child: const FeedsWidget(),
                  );
                },
              ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
