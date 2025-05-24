import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:grocery_app/models/orders_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grocery_app/consts/firebase_consts.dart';

class OrdersProvider with ChangeNotifier {
  static List<OrderModel> _orders = [];
  bool _isFetching = false;
  
  List<OrderModel> get getOrders {
    return _orders;
  }

  Future<void> fetchOrders() async {
    // Prevent multiple simultaneous fetches
    if (_isFetching) return;
    _isFetching = true;
    
    final User? user = authInstance.currentUser;
    
    // Clear orders if no user is logged in
    if (user == null) {
      _orders = [];
      _isFetching = false;
      notifyListeners();
      return;
    }
    
    try {
      final List<OrderModel> tempOrders = [];
      
      // Fetch main orders
      final QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true)
          .get();
      
      // Process each order
      for (var doc in ordersSnapshot.docs) {
        final orderData = doc.data() as Map<String, dynamic>;
        final String orderId = orderData['orderId'];
        final Timestamp orderDate = orderData['orderDate'];
        final String status = orderData['status'] ?? 'pending';
        final String userName = orderData['userName'] ?? 'Guest';
        
        // Get items for this order
        final QuerySnapshot itemsSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .collection('items')
            .get();
        
        // If there are no items in the subcollection, still display the order
        if (itemsSnapshot.docs.isEmpty) {
          tempOrders.add(OrderModel(
            orderId: orderId,
            userId: user.uid,
            productId: '',
            userName: userName,
            price: orderData['totalPrice'] ?? 0.0,
            imageUrl: '',
            quantity: 0,
            orderDate: orderDate,
            status: status,
          ));
        } else {
          // Otherwise, add each item as a separate OrderModel for display
          for (var itemDoc in itemsSnapshot.docs) {
            final itemData = itemDoc.data() as Map<String, dynamic>;
            
            tempOrders.add(OrderModel(
              orderId: orderId,
              userId: user.uid,
              productId: itemData['productId'] ?? '',
              userName: userName,
              price: itemData['price'] ?? 0.0,
              imageUrl: itemData['imageUrl'] ?? '',
              quantity: itemData['quantity'] ?? 1,
              orderDate: orderDate,
              status: status,
            ));
          }
        }
      }
      
      _orders = tempOrders;
    } catch (error) {
      print("Error fetching orders: $error");
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }
  
  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
          
      // Update local state
      final orderIndex = _orders.indexWhere((order) => order.orderId == orderId);
      if (orderIndex != -1) {
        // Create a new instance with updated status
        final updatedOrder = OrderModel(
          orderId: _orders[orderIndex].orderId,
          userId: _orders[orderIndex].userId,
          productId: _orders[orderIndex].productId,
          userName: _orders[orderIndex].userName,
          price: _orders[orderIndex].price,
          imageUrl: _orders[orderIndex].imageUrl,
          quantity: _orders[orderIndex].quantity,
          orderDate: _orders[orderIndex].orderDate,
          status: newStatus,
        );
        
        // Replace the old order with updated one
        _orders.removeAt(orderIndex);
        _orders.insert(orderIndex, updatedOrder);
        notifyListeners();
      }
    } catch (error) {
      print("Error updating order status: $error");
      rethrow;
    }
  }
  
  // Delete an order
  Future<void> deleteOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .delete();
          
      // Remove from local state
      _orders.removeWhere((order) => order.orderId == orderId);
      notifyListeners();
    } catch (error) {
      print("Error deleting order: $error");
      rethrow;
    }
  }
}
