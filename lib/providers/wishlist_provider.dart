import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/models/wishlist_model.dart';

class WishlistProvider with ChangeNotifier {
  Map<String, WishlistModel> _wishlistItems = {};

  Map<String, WishlistModel> get getWishlistItems {
    return _wishlistItems;
  }

  // void addRemoveProductToWishlist({required String productId}) {
  //   if (_wishlistItems.containsKey(productId)) {
  //     removeOneItem(productId);
  //   } else {
  //     _wishlistItems.putIfAbsent(
  //         productId,
  //         () => WishlistModel(
  //             id: DateTime.now().toString(), productId: productId));
  //   }
  //   notifyListeners();
  // }

  final userCollection = FirebaseFirestore.instance.collection('users');

  Future<void> fetchWishlist() async {
    final User? user = authInstance.currentUser;
    
    // Clear wishlist if no user is logged in
    if (user == null) {
      _wishlistItems.clear();
      notifyListeners();
      return;
    }
    
    try {
      final DocumentSnapshot userDoc = await userCollection.doc(user.uid).get();
      
      // Check if document exists
      if (!userDoc.exists) {
        _wishlistItems.clear();
        notifyListeners();
        return;
      }
      
      // Check if userWish field exists and is a list
      if (!userDoc.data().toString().contains('userWish')) {
        _wishlistItems.clear();
        notifyListeners();
        return;
      }
      
      // Get userWish data - with null safety
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null || userData['userWish'] == null) {
        _wishlistItems.clear();
        notifyListeners();
        return;
      }
      
      final userWish = userData['userWish'] as List<dynamic>;
      _wishlistItems.clear(); // Clear existing items
      
      for (int i = 0; i < userWish.length; i++) {
        _wishlistItems.putIfAbsent(
          userWish[i]['productId'],
          () => WishlistModel(
            id: userWish[i]['wishlistId'],
            productId: userWish[i]['productId'],
          ),
        );
      }
      
      notifyListeners();
    } catch (error) {
      print("Error fetching wishlist: $error");
      _wishlistItems.clear();
      notifyListeners();
    }
  }

  Future<void> removeOneItem({
    required String wishlistId,
    required String productId,
  }) async {
    final User? user = authInstance.currentUser;
    await userCollection.doc(user!.uid).update({
      'userWish': FieldValue.arrayRemove([
        {
          'wishlistId': wishlistId,
          'productId': productId,
        }
      ])
    });
    _wishlistItems.remove(productId);
    await fetchWishlist();
    notifyListeners();
  }

  Future<void> clearOnlineWishlist() async {
    final User? user = authInstance.currentUser;
    await userCollection.doc(user!.uid).update({
      'userWish': [],
    });
    _wishlistItems.clear();
    notifyListeners();
  }

  void clearLocalWishlist() {
    _wishlistItems.clear();
    notifyListeners();
  }
}
