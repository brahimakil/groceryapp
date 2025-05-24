import 'package:flutter/material.dart';
import 'package:grocery_app/models/viewed_model.dart';

class ViewedProdProvider with ChangeNotifier {
  final Map<String, ViewedProdModel> _viewedProdlistItems = {};

  Map<String, ViewedProdModel> get getViewedProdlistItems {
    return _viewedProdlistItems;
  }

  void addProductToHistory({required String productId}) {
    // Don't add if it already exists (just move it to the top by removing and re-adding later)
    if (_viewedProdlistItems.containsKey(productId)) {
      // Store the existing item
      final existingItem = _viewedProdlistItems[productId];
      // Remove it
      _viewedProdlistItems.remove(productId);
      // Re-add it with the same ID (to maintain the same reference)
      if (existingItem != null) {
        _viewedProdlistItems[productId] = existingItem;
        notifyListeners();
        return;
      }
    }
    
    // Add new item
    _viewedProdlistItems.putIfAbsent(
      productId,
      () => ViewedProdModel(
        id: DateTime.now().toString(),
        productId: productId,
      ),
    );

    notifyListeners();
  }

  void removeFromHistory(String productId) {
    _viewedProdlistItems.remove(productId);
    notifyListeners();
  }

  void clearHistory() {
    _viewedProdlistItems.clear();
    notifyListeners();
  }
  
  // Limit history to most recent N items
  void limitHistoryItems(int maxItems) {
    if (_viewedProdlistItems.length <= maxItems) return;
    
    final itemsList = _viewedProdlistItems.entries.toList();
    // Sort by recency (if you have a timestamp in your model)
    // itemsList.sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));
    
    // Keep only the most recent items
    final itemsToKeep = itemsList.take(maxItems).map((e) => e.key).toSet();
    _viewedProdlistItems.removeWhere((key, _) => !itemsToKeep.contains(key));
    
    notifyListeners();
  }
}
