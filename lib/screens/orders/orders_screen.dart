import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/widgets/back_widget.dart';
import 'package:grocery_app/widgets/empty_screen.dart';
import 'package:provider/provider.dart';

import '../../providers/orders_provider.dart';
import '../../models/orders_model.dart';
import '../../services/utils.dart';
import '../../widgets/text_widget.dart';
import 'orders_widget.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/OrdersScreen';

  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
  }
  
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });
    
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    
    try {
      await ordersProvider.fetchOrders();
    } catch (error) {
      print("Error fetching orders: $error");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _refreshOrders(BuildContext context) async {
    await _fetchOrders();
    return Future.value();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final ordersList = ordersProvider.getOrders;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (ordersList.isEmpty) {
      return const EmptyScreen(
        title: 'You didnt place any order yet',
        subtitle: 'order something and make me happy :)',
        buttonText: 'Shop now',
        imagePath: 'assets/images/cart.png',
      );
    }
    
    // Group items by order ID
    Map<String, List<OrderModel>> ordersMap = {};
    for (var order in ordersList) {
      if (!ordersMap.containsKey(order.orderId)) {
        ordersMap[order.orderId] = [];
      }
      ordersMap[order.orderId]!.add(order);
    }
    
    // Sort orders by date (newest first)
    final sortedOrderIds = ordersMap.keys.toList()
      ..sort((a, b) {
        final dateA = ordersMap[a]!.first.orderDate.millisecondsSinceEpoch;
        final dateB = ordersMap[b]!.first.orderDate.millisecondsSinceEpoch;
        return dateB.compareTo(dateA); // Latest first
      });
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: TextWidget(
          text: 'Your Orders (${sortedOrderIds.length})',
          color: color,
          textSize: 24,
          isTitle: true,
        ),
        actions: [
          IconButton(
            onPressed: () {
              _refreshOrders(context);
            },
            icon: Icon(
              Icons.refresh,
              color: color,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshOrders(context),
        child: ListView.builder(
          itemCount: sortedOrderIds.length,
          itemBuilder: (ctx, index) {
            final orderId = sortedOrderIds[index];
            final orderItems = ordersMap[orderId]!;
            final firstOrder = orderItems.first;
            
            return _buildOrderCard(context, orderId, firstOrder, orderItems);
          },
        ),
      ),
    );
  }
  
  Widget _buildOrderCard(BuildContext context, String orderId, OrderModel orderInfo, List<OrderModel> items) {
    final Color color = Utils(context).color;
    final orderDate = DateTime.fromMillisecondsSinceEpoch(
      orderInfo.orderDate.millisecondsSinceEpoch
    );
    final formattedDate = '${orderDate.day}/${orderDate.month}/${orderDate.year}';
    
    // Calculate total price
    double totalPrice = 0;
    for (var item in items) {
      totalPrice += item.priceAsDouble;
    }
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderId.substring(0, 6)}',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(orderInfo.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(orderInfo.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Order date
            Text(
              'Date: $formattedDate',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            
            // Order items
            const Text(
              'Items:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // List of items
            for (var item in items)
              if (item.productId.isNotEmpty)
                Provider<OrderModel>.value(
                  value: item,
                  child: const OrderWidget(),
                ),
            
            const Divider(),
            
            // Order total
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: \$${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(String status) {
    if (status.isEmpty) return 'Unknown';
    return '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}';
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
