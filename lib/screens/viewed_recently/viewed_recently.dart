import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/providers/viewed_prod_provider.dart';
import 'package:grocery_app/widgets/back_widget.dart';
import 'package:grocery_app/widgets/empty_screen.dart';
import 'package:provider/provider.dart';

import '../../services/global_methods.dart';
import '../../services/utils.dart';
import '../../widgets/text_widget.dart';
import 'viewed_widget.dart';

class ViewedRecentlyScreen extends StatefulWidget {
  static const routeName = '/ViewedRecentlyScreen';

  const ViewedRecentlyScreen({Key? key}) : super(key: key);

  @override
  _ViewedRecentlyScreenState createState() => _ViewedRecentlyScreenState();
}

class _ViewedRecentlyScreenState extends State<ViewedRecentlyScreen> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    Color color = Utils(context).color;
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);
    final viewedProdItemsList = viewedProdProvider.getViewedProdlistItems.values
        .toList()
        .reversed
        .toList();
    
    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Recently Viewed',
          color: color,
          textSize: 22.0,
          isTitle: true,
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const BackWidget(),
        actions: [
          if (viewedProdItemsList.isNotEmpty) // Only show clear button if there are items
            IconButton(
              onPressed: () {
                GlobalMethods.warningDialog(
                  title: 'Clear History',
                  subtitle: 'Are you sure you want to clear your viewing history?',
                  fct: () {
                    setState(() {
                      _isLoading = true;
                    });
                    viewedProdProvider.clearHistory();
                    setState(() {
                      _isLoading = false;
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  context: context,
                );
              },
              icon: Icon(
                IconlyBroken.delete,
                color: color,
              ),
            )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : viewedProdItemsList.isEmpty 
              ? const EmptyScreen(
                  title: 'Your history is empty',
                  subtitle: 'No products have been viewed yet!',
                  buttonText: 'Shop now',
                  imagePath: 'assets/images/history.png',
                )
              : ListView.builder(
                  itemCount: viewedProdItemsList.length,
                  itemBuilder: (ctx, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: ChangeNotifierProvider.value(
                        value: viewedProdItemsList[index],
                        child: const ViewedRecentlyWidget(),
                      ),
                    );
                  },
                ),
    );
  }
}
