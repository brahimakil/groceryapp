import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final String productId;
  final String userName;
  final dynamic price;
  final String imageUrl;
  final dynamic quantity;
  final Timestamp orderDate;
  final String status;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.productId,
    required this.userName,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.orderDate,
    required this.status,
  });

  double get priceAsDouble {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  int get quantityAsInt {
    if (quantity is int) return quantity;
    if (quantity is String) return int.tryParse(quantity) ?? 1;
    return 1;
  }
}
