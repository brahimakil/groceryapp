import 'package:flutter/material.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/providers/categories_provider.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';
import '../inner_screens/cat_screen.dart';
import '../services/utils.dart';
import '../widgets/base64_image_widget.dart';

class CategoriesScreen extends StatelessWidget {
  static const routeName = "/CategoriesScreen";
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final utils = Utils(context);
    Color color = utils.color;
    final categoriesProvider = Provider.of<CategoriesProvider>(context);
    List<CategoryModel> categories = categoriesProvider.categories;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: TextWidget(
          text: 'Categories',
          color: color,
          textSize: 24,
          isTitle: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: categories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 80,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 20),
                    TextWidget(
                      text: 'No categories available',
                      color: color,
                      textSize: 20,
                    ),
                  ],
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: categories.length,
                itemBuilder: (ctx, index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context, 
                        CategoryScreen.routeName,
                        arguments: {
                          'categoryId': category.id,
                          'categoryName': category.name,
                        }
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                                child: Base64ImageWidget(
                                  base64String: category.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                  errorWidget: Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.image_not_supported, 
                                      color: Colors.grey.shade500,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.center,
                              child: TextWidget(
                                text: category.name,
                                color: color,
                                textSize: 14,
                                isTitle: true,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
