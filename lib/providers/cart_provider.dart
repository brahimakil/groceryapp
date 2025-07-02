import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:uuid/uuid.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartModel> _cartItems = {};

  Map<String, CartModel> get getCartItems {
    return _cartItems;
  }

  // Add item to Firestore userCart
  Future<void> addProductToCart({
    required String productId,
    required int quantity,
  }) async {
    final User? user = authInstance.currentUser;
    if (user == null) {
      print("User not logged in. Cannot add to Firestore cart.");
      return;
    }
    final _uid = user.uid;

    try {
      // Check if product already exists in cart
      if (_cartItems.containsKey(productId)) {
        print("Product $productId already in cart. Skipping duplicate addition.");
        return; // Don't add duplicates, just return
      }

      final cartId = const Uuid().v4();

      // Update local state immediately for instant UI feedback
      _cartItems[productId] = CartModel(
        id: cartId,
        productId: productId,
        quantity: quantity,
      );
      notifyListeners(); // Notify immediately for instant UI update

      // Then update Firestore in the background
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'userCart': FieldValue.arrayUnion([
          {
            'cartId': cartId,
            'productId': productId,
            'quantity': quantity,
          }
        ])
      });

      print("Added product $productId to cart for user $_uid");
    } catch (error) {
      print("Error adding to cart in Firestore: $error");
      
      // Revert local state if Firestore update failed
      _cartItems.remove(productId);
      notifyListeners();
      
      rethrow;
    }
  }


  // Reduce quantity (Conceptual - needs more robust implementation)
  void reduceQuantityByOne(String productId) {
     // Needs logic to update Firestore quantity or remove if quantity reaches 0
     // and update local state
    if (_cartItems.containsKey(productId)) {
       if (_cartItems[productId]!.quantity > 1) {
         _cartItems.update(productId, (value) => CartModel(id: value.id, productId: productId, quantity: value.quantity -1));
       } else {
         // removeProductFromCart(productId); // Needs implementation
       }
       notifyListeners();
    }
  }

  // Increase quantity (Conceptual - needs more robust implementation)
  void increaseQuantityByOne(String productId) {
      // Needs logic to update Firestore quantity
      // and update local state
     if (_cartItems.containsKey(productId)) {
       _cartItems.update(productId, (value) => CartModel(id: value.id, productId: productId, quantity: value.quantity + 1));
       notifyListeners();
     }
  }

  // Remove item completely (Updated to handle Firestore removal)
  Future<void> removeOneItem(String productId) async {
    final User? user = authInstance.currentUser;
    if (user == null) {
      print("User not logged in. Cannot remove from Firestore cart.");
      // Handle local removal if needed for guest carts
      _cartItems.remove(productId);
      notifyListeners();
      return;
    }
    final _uid = user.uid;

    // --- Firestore Removal Logic ---
    try {
       // 1. Get the current user document
      final DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(_uid);
      final DocumentSnapshot userDocSnap = await userDocRef.get();

       if (!userDocSnap.exists) {
         print("User document not found for removal.");
          _cartItems.remove(productId); // Still remove locally
         notifyListeners();
         return;
       }

       final userData = userDocSnap.data() as Map<String, dynamic>?;
       if (userData == null || userData['userCart'] == null || userData['userCart'] is! List) {
         print("User cart data invalid for removal.");
          _cartItems.remove(productId); // Still remove locally
         notifyListeners();
         return;
       }

       // 2. Find the specific map object to remove
       List<dynamic> currentCart = List.from(userData['userCart']);
       Map<String, dynamic>? itemToRemove;
       for (var item in currentCart) {
         if (item is Map<String, dynamic> && item['productId'] == productId) {
           itemToRemove = item;
           break;
         }
       }

       // 3. Update Firestore if the item was found
       if (itemToRemove != null) {
         await userDocRef.update({
           'userCart': FieldValue.arrayRemove([itemToRemove])
         });
         print("Removed product $productId from Firestore cart for user $_uid");
       } else {
          print("Product $productId not found in Firestore cart array for removal.");
       }

    } catch(error) {
        print("Error removing item from Firestore: $error");
        // Optionally rethrow or show error to user
        rethrow;
    }
    // --- End Firestore Removal Logic ---

    // Remove locally regardless of Firestore success/failure for immediate UI update
    _cartItems.remove(productId);
    notifyListeners();
    print("Locally removed product $productId.");
  }


  // Fetch cart from Firestore
  Future<void> fetchCart() async {
    final User? user = authInstance.currentUser;
    if (user == null) {
       print("User not logged in. Cannot fetch Firestore cart.");
      _cartItems.clear();
      notifyListeners();
      return;
    }
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      print("User document does not exist.");
       _cartItems.clear();
      notifyListeners();
      return;
    }

     final data = userDoc.data() as Map<String, dynamic>?;
     if (data == null || data['userCart'] == null || data['userCart'] is! List) {
       print("User cart data is missing or not a list.");
       _cartItems.clear(); // Ensure cart is empty if no data
       notifyListeners();
       return;
     }

     final List<dynamic> cartData = data['userCart'];
     final Map<String, CartModel> fetchedCartItems = {};

     for (var item in cartData) {
       if (item is Map<String, dynamic> && item['productId'] != null && item['quantity'] != null) {
         try {
           final cartModel = CartModel(
              // Use cartId from Firestore if available, else generate one or use productId
             id: item['cartId'] ?? item['productId'],
             productId: item['productId'],
             quantity: item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1,
           );
           // Use productId as the key for the map
           fetchedCartItems[cartModel.productId] = cartModel;
         } catch (e) {
           print("Error parsing cart item: $item, Error: $e");
         }
       }
     }
     _cartItems = fetchedCartItems;
     print("Fetched ${_cartItems.length} items from cart.");
    notifyListeners();
  }

  // Clear cart (needs Firestore update)
  Future<void> clearOnlineCart() async {
     final User? user = authInstance.currentUser;
     if (user == null) return;
     final _uid = user.uid;
     try {
       await FirebaseFirestore.instance.collection('users').doc(_uid).update({
         'userCart': [], // Set to empty array
       });
       _cartItems.clear(); // Clear local state
       notifyListeners();
       print("Cleared online cart for user $_uid");
     } catch (error) {
        print("Error clearing online cart: $error");
        rethrow;
     }
  }

  void clearLocalCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
