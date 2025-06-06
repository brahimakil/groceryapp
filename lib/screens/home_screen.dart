import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/inner_screens/feeds_screen.dart';
import 'package:grocery_app/inner_screens/on_sale_screen.dart';
import 'package:grocery_app/providers/dark_theme_provider.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as custom_badge;

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
import '../inner_screens/search_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Fetch products after the first frame if they are missing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductsProvider>(context, listen: false);
      if (mounted && productProvider.getProducts.isEmpty) {
        print("HomeScreen initState: Products empty, attempting fetch...");
        productProvider.fetchProducts().catchError((error) {
           print("Error fetching products from HomeScreen initState: $error");
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Could not reload products: $error'),
                 backgroundColor: Colors.red.shade600,
                 behavior: SnackBarBehavior.floating,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
             );
           }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Utils utils = Utils(context);
    final themeState = utils.getTheme;
    final Color color = Utils(context).color;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Size size = utils.getScreenSize;
    final productProviders = Provider.of<ProductsProvider>(context);
    final categoriesProvider = Provider.of<CategoriesProvider>(context);
    List<ProductModel> allProducts = productProviders.getProducts;
    List<ProductModel> productsOnSale = productProviders.getOnSaleProducts;
    List<CategoryModel> categories = categoriesProvider.categories;
    
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                title: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                  ).createShader(bounds),
                  child: const Text(
                    'Fresh Market',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, SearchScreen.routeName);
                    },
                    icon: Icon(IconlyLight.search, color: color),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      final unreadCount = notificationProvider.unreadCount;
                      
                      Widget iconButton = IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pushNamed(context, NotificationsScreen.routeName);
                        },
                        icon: Icon(IconlyLight.notification, color: color),
                      );

                      if (unreadCount > 0) {
                        return custom_badge.Badge(
                          badgeStyle: custom_badge.BadgeStyle(
                            badgeColor: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 0,
                            padding: const EdgeInsets.all(4),
                          ),
                          position: custom_badge.BadgePosition.topEnd(top: 8, end: 8),
                          badgeContent: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: iconButton,
                        );
                      }
                      
                      return iconButton;
                    },
                  ),
                ),
              ],
            ),

            // Hero Banner Section
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  height: size.height * 0.25,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Swiper(
                      itemBuilder: (BuildContext context, int index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              Constss.offerImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.primaryColor.withOpacity(0.8),
                                      theme.primaryColor,
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image_outlined, 
                                    color: Colors.white, size: 48),
                                ),
                              ),
                            ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      autoplay: true,
                      itemCount: Constss.offerImages.length,
                      pagination: SwiperPagination(
                        alignment: Alignment.bottomCenter,
                        margin: const EdgeInsets.only(bottom: 16),
                        builder: DotSwiperPaginationBuilder(
                          color: Colors.white.withOpacity(0.5),
                          activeColor: Colors.white,
                          size: 8,
                          activeSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // On Sale Section
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              IconlyBold.discount,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Special Offers',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          GlobalMethods.navigateTo(
                              ctx: context, routeName: OnSaleScreen.routeName);
                        },
                        icon: Icon(
                          IconlyLight.arrowRight2,
                          color: theme.primaryColor,
                          size: 18,
                        ),
                        label: Text(
                          'View All',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // On Sale Products Horizontal List
            SliverToBoxAdapter(
              child: Container(
                height: MediaQuery.of(context).size.width > 800 ? 180 : size.height * 0.24,
                child: ListView.builder(
                  itemCount: productsOnSale.length < 10 ? productsOnSale.length : 10,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemBuilder: (ctx, index) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width > 800 ? 320 : size.width * 0.52,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: ChangeNotifierProvider.value(
                          value: productsOnSale[index],
                          child: const OnSaleWidget(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Our Products Section
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              IconlyBold.category,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Our Products',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          GlobalMethods.navigateTo(
                              ctx: context, routeName: FeedsScreen.routeName);
                        },
                        icon: Icon(
                          IconlyLight.arrowRight2,
                          color: theme.primaryColor,
                          size: 18,
                        ),
                        label: Text(
                          'Browse All',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Products Grid
            if (allProducts.isEmpty) 
              SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconlyLight.bag,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No products found",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else 
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 :
                                  (MediaQuery.of(context).size.width > 800 ? 4 : 2),
                    childAspectRatio: MediaQuery.of(context).size.width > 800 ? 0.85 : 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      return ChangeNotifierProvider.value(
                        value: allProducts[index],
                        child: const FeedsWidget(),
                      );
                    },
                    childCount: allProducts.length < 8 ? allProducts.length : 8,
                  ),
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}
