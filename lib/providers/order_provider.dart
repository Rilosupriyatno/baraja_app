import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/order.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];

  List<Order> get orders => _orders;

  // Get all orders
  List<Order> get allOrders => List.from(_orders);

  // Get specific order by ID

  Order? getOrderById(String orderId) {
    return _orders.firstWhere((order) => order.id == orderId);
  }


  // Add a new order
  Future<void> addOrder(Order order) async {
    _orders.add(order);
    notifyListeners();
    await _saveOrders();
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      _orders[orderIndex].status = newStatus;
      notifyListeners();
      await _saveOrders();
    }
  }

  // Delete an order (could be used for admin purposes or order cancellation)
  Future<void> deleteOrder(String orderId) async {
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
    await _saveOrders();
  }

  // Load orders from SharedPreferences
  Future<void> loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString('orders');

      if (ordersJson != null) {
        final List<dynamic> decodedData = json.decode(ordersJson);
        _orders = decodedData
            .map((orderData) => Order.fromMap(orderData))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading orders: $e');
      }
    }
  }

  // Save orders to SharedPreferences
  Future<void> _saveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersData = _orders.map((order) => order.toMap()).toList();
      await prefs.setString('orders', json.encode(ordersData));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving orders: $e');
      }
    }
  }
}