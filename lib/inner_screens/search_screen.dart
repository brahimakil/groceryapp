import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/providers/categories_provider.dart';
import 'package:grocery_app/widgets/feed_items.dart';
import 'package:grocery_app/widgets/empty_products_widget.dart';
import 'package:grocery_app/widgets/base64_image_widget.dart';
import 'package:provider/provider.dart';
import '../services/utils.dart';

class SearchScreen extends StatefulWidget {
  static const routeName = "/SearchScreen";
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ProductModel> searchResults = [];
  List<String> recentSearches = [];
  bool isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
    final results = productsProvider.searchQuery(query);
    
    setState(() {
      searchResults = results;
      isSearching = false;
    });

    // Add to recent searches if not empty and not already present
    if (query.trim().isNotEmpty && !recentSearches.contains(query.trim())) {
      setState(() {
        recentSearches.insert(0, query.trim());
        if (recentSearches.length > 10) {
          recentSearches.removeLast();
        }
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      searchResults = [];
      isSearching = false;
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = Utils(context).color;
    final size = Utils(context).getScreenSize;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          icon: Icon(
            IconlyLight.arrowLeft,
            color: color,
          ),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _searchFocusNode.hasFocus 
                  ? theme.primaryColor.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _performSearch,
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: "Search for products...",
              hintStyle: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                IconlyLight.search,
                color: color.withOpacity(0.6),
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: Icon(
                        IconlyLight.closeSquare,
                        color: color.withOpacity(0.6),
                        size: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(
              color: color,
              fontSize: 16,
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(context, theme, isDark, color, size),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, bool isDark, Color color, Size size) {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState(theme, color);
    }

    if (isSearching) {
      return _buildLoadingState(theme);
    }

    if (searchResults.isEmpty) {
      return _buildNoResultsState(theme, color);
    }

    return _buildSearchResults(context, theme, size);
  }

  Widget _buildEmptyState(ThemeData theme, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            Text(
              "Recent Searches",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSearches.map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconlyLight.timeCircle,
                          size: 16,
                          color: color.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          search,
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Real categories from database
          Consumer<CategoriesProvider>(
            builder: (context, categoriesProvider, child) {
              if (categoriesProvider.categories.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Browse Categories",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRealCategories(theme, color, categoriesProvider),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRealCategories(ThemeData theme, Color color, CategoriesProvider categoriesProvider) {
    final categories = categoriesProvider.categories;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length > 8 ? 8 : categories.length, // Limit to 8 categories
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            _searchController.text = category.name;
            _performSearch(category.name);
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: category.imageUrl.isNotEmpty
                        ? Base64ImageWidget(
                            base64String: category.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              color: theme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                IconlyLight.category,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                            ),
                            errorWidget: Container(
                              color: theme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                IconlyLight.category,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                            ),
                          )
                        : Icon(
                            IconlyLight.category,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            "Searching...",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme, Color color) {
    return const EmptyProdWidget(
      text: 'No products found for your search.\nTry different keywords.',
    );
  }

  Widget _buildSearchResults(BuildContext context, ThemeData theme, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "${searchResults.length} result${searchResults.length != 1 ? 's' : ''} found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 :
                            (MediaQuery.of(context).size.width > 800 ? 4 : 2),
              childAspectRatio: MediaQuery.of(context).size.width > 800 ? 0.9 : 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              return ChangeNotifierProvider.value(
                value: searchResults[index],
                child: const FeedsWidget(),
              );
            },
          ),
        ),
      ],
    );
  }
} 