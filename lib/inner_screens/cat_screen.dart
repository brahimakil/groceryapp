import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/consts/contss.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:provider/provider.dart';

import '../services/utils.dart';
import '../widgets/back_widget.dart';
import '../widgets/empty_products_widget.dart';
import '../widgets/feed_items.dart';
import '../widgets/text_widget.dart';
import '../widgets/base64_image_widget.dart';
import '../services/global_methods.dart';

class CategoryScreen extends StatefulWidget {
  static const routeName = "/CategoryScreenState";
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController? _searchTextController = TextEditingController();
  final FocusNode _searchTextFocusNode = FocusNode();
  List<ProductModel> listProdcutSearch = [];
  late String categoryId;
  late String categoryName;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map<String, dynamic>) {
        categoryId = args['categoryId'] as String? ?? '';
        categoryName = args['categoryName'] as String? ?? 'Category';
        print("Received categoryId: $categoryId, categoryName: $categoryName");

        if (categoryId.isNotEmpty) {
          _fetchCategoryProducts();
        } else {
          print("Error: Category ID is empty.");
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print("Error: Invalid arguments passed to CategoryScreen.");
        categoryName = "Error";
        categoryId = "";
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCategoryProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<ProductsProvider>(context, listen: false)
          .fetchProductsByCategory(categoryId);
    } catch (error) {
      print("Error fetching products for category $categoryId: $error");
      if (mounted) {
        GlobalMethods.errorDialog(subtitle: "Could not load products: $error", context: context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchTextController!.dispose();
    _searchTextFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    final productsProvider = Provider.of<ProductsProvider>(context);
    List<ProductModel> productsByCategory = productsProvider.getProducts;
    return Scaffold(
      appBar: AppBar(
        leading: const BackWidget(),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        title: TextWidget(
          text: categoryName,
          color: color,
          textSize: 20.0,
          isTitle: true,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: productsByCategory.isEmpty
                      ? ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: EmptyProdWidget(
                                text: 'No products found for this category',
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 
                                          (MediaQuery.of(context).size.width > 800 ? 3 : 2),
                              childAspectRatio: MediaQuery.of(context).size.width > 800 ? 1.2 : 0.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: productsByCategory.length,
                            itemBuilder: (ctx, index) {
                              return ChangeNotifierProvider.value(
                                value: productsByCategory[index],
                                child: const FeedsWidget(),
                              );
                            },
                          ),
                        ),
                );
              },
            ),
    );
  }
}
