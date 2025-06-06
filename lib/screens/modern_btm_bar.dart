import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:badges/badges.dart' as custom_badge;
import 'package:provider/provider.dart';
import '../consts/modern_theme.dart';
import '../providers/cart_provider.dart';
import '../widgets/modern_text_widget.dart';
import 'categories.dart';
import 'home_screen.dart';
import 'user.dart';
import 'cart/cart_screen.dart';

class ModernBottomBarScreen extends StatefulWidget {
  const ModernBottomBarScreen({Key? key}) : super(key: key);

  @override
  State<ModernBottomBarScreen> createState() => _ModernBottomBarScreenState();
}

class _ModernBottomBarScreenState extends State<ModernBottomBarScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Map<String, dynamic>> _pages = [
    {
      'page': const HomeScreen(),
      'title': 'Home',
      'icon': IconlyLight.home,
      'activeIcon': IconlyBold.home,
    },
    {
      'page': const CategoriesScreen(),
      'title': 'Categories',
      'icon': IconlyLight.category,
      'activeIcon': IconlyBold.category,
    },
    {
      'page': const CartScreen(),
      'title': 'Cart',
      'icon': IconlyLight.bag,
      'activeIcon': IconlyBold.bag,
    },
    {
      'page': const UserScreen(),
      'title': 'Profile',
      'icon': IconlyLight.profile,
      'activeIcon': IconlyBold.profile,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectedPage(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex]['page'],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(
              horizontal: ModernTheme.spaceM,
              vertical: ModernTheme.spaceS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_pages.length, (index) {
                final isSelected = index == _selectedIndex;
                final page = _pages[index];
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _selectedPage(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: ModernTheme.spaceS,
                        vertical: ModernTheme.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ModernTheme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: _buildIcon(index, isSelected, page),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? ModernTheme.primaryColor
                                  : theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            child: Text(page['title']),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(int index, bool isSelected, Map<String, dynamic> page) {
    if (index == 2) { // Cart tab
      return Consumer<CartProvider>(
        builder: (_, cartProvider, __) {
          final cartItemsCount = cartProvider.getCartItems.length;
          
          Widget iconWidget = Icon(
            isSelected ? page['activeIcon'] : page['icon'],
            color: isSelected
                ? ModernTheme.primaryColor
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 24,
          );

          if (cartItemsCount > 0) {
            return custom_badge.Badge(
              badgeStyle: custom_badge.BadgeStyle(
                badgeColor: ModernTheme.errorColor,
                borderRadius: BorderRadius.circular(10),
                elevation: 0,
              ),
              position: custom_badge.BadgePosition.topEnd(top: -8, end: -8),
              badgeContent: Text(
                cartItemsCount > 99 ? '99+' : cartItemsCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: iconWidget,
            );
          }
          
          return iconWidget;
        },
      );
    }

    return Icon(
      isSelected ? page['activeIcon'] : page['icon'],
      color: isSelected
          ? ModernTheme.primaryColor
          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      size: 24,
    );
  }
} 