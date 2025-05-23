import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';


class OrderService {
  // Change this to your actual API base URL
  final String? baseUrl = dotenv.env['BASE_URL'];

  // Method to create a new order
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String userId,
    required String userName,
    required OrderType orderType,
    String? tableNumber,
    String? deliveryAddress,
    TimeOfDay? pickupTime,
    String? paymentMethod,
    String? paymentMethodName,
    String? bankName,
    String? bankCode,
    required int subtotal,
    required int discount,
    String? voucherCode,
    required Map<String, String?> paymentDetails,
  }) async {
    try {
      // Prepare order data
      final orderData = {
        'userId': userId,
        'userName': userName,
        'items': items,
        'orderType': orderType
            .toString()
            .split('.')
            .last,
        'tableNumber': tableNumber,
        'deliveryAddress': deliveryAddress,
        'pickupTime': pickupTime,
        'paymentDetails': paymentDetails,
        'pricing': {
          'subtotal': subtotal,
          'discount': discount,
          'total': subtotal - discount,
        },
        'voucherCode': voucherCode,
        'orderDate': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      print(orderData);

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/api/orderApp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Order created successfully
        return jsonDecode(response.body);
      } else {
        // Handle error
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to create order: ${errorBody['message'] ??
            'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  // Fungsi untuk mendapatkan riwayat pesanan pengguna
  Future<List<Order>> getUserOrderHistory() async {
    try {
      // Ambil userId dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/history/$userId'),
        headers: {
          'Content-Type': 'application/json',
          // Tambahkan header authorization jika diperlukan
          'Authorization': 'Bearer ${prefs.getString('token') ?? ''}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ordersData = responseData['orders'];

        return ordersData.map((orderData) => _mapToOrder(orderData)).toList();
      } else {
        throw Exception('Failed to load order history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching order history: $e');
      return [];
    }
  }

  // Fungsi untuk memetakan data JSON dari API ke model Order Flutter
  Order _mapToOrder(Map<String, dynamic> orderData) {
    // Mengonversi status dari string ke enum OrderStatus
    OrderStatus getOrderStatus(String statusString) {
      switch (statusString) {
        case 'Pending':
          return OrderStatus.pending;
        case 'Processing':
          return OrderStatus.processing;
        case 'On The Way':
          return OrderStatus.onTheWay;
        case 'Ready':
          return OrderStatus.ready;
        case 'Completed':
          return OrderStatus.completed;
        case 'Cancelled':
          return OrderStatus.cancelled;
        default:
          return OrderStatus.pending;
      }
    }

    // Mengonversi orderType dari string ke enum OrderType
    OrderType getOrderType(String typeString) {
      switch (typeString) {
        case 'Delivery':
          return OrderType.delivery;
        case 'Pick-up':
        case 'Pickup':
          return OrderType.pickup;
        case 'Dine-In':
        default:
          return OrderType.dineIn;
      }
    }

    // Membuat list CartItem dari items pada orderData
    List<CartItem> cartItems = [];
    if (orderData['items'] != null) {
      for (var item in orderData['items']) {
        // Mendapatkan informasi menuItem
        final menuItem = item['menuItem'];

        List<Map<String, dynamic>> addonsList = [];
        if (item['addons'] != null && item['addons'].isNotEmpty) {
          for (var addon in item['addons']) {
            addonsList.add({
              'name': addon['label'] ?? '',
              'price': addon['price'] ?? 0,
            });
          }
        }

        List<Map<String, dynamic>> toppingsList = [];
        if (item['toppings'] != null && item['toppings'].isNotEmpty) {
          for (var topping in item['toppings']) {
            toppingsList.add({
              'name': topping['name'] ?? '',
              'price': topping['price'] ?? 0,
            });
          }
        }

        cartItems.add(CartItem(
          id: menuItem['_id'] ?? '',
          name: menuItem['name'] ?? 'Unknown Item',
          imageUrl: menuItem['imageURL'] ?? 'https://via.placeholder.com/150',
          price: menuItem['price'] ?? 0,
          totalprice: item['subtotal'] ?? 0,
          quantity: item['quantity'] ?? 1,
          addons: addonsList,  // Menggunakan List<Map<String, dynamic>>
          toppings: toppingsList,  // Menggunakan List<Map<String, dynamic>>
        ));
      }
    }

    // Menghitung total dan subtotal
    int subtotal = 0;
    for (var item in cartItems) {
      subtotal += item.totalprice;
    }

    // Menghitung diskon jika ada voucher
    int discount = 0;
    if (orderData['voucher'] != null) {
      // Implementasikan perhitungan diskon sesuai dengan format data voucher Anda
      // Misalnya:
      // discount = orderData['voucher']['discountAmount'] ?? 0;
    }

    // Total setelah diskon
    int total = subtotal - discount;

    // Membuat objek Order
    return Order(
      id: orderData['_id'] ?? '',
      items: cartItems,
      orderType: getOrderType(orderData['orderType'] ?? 'Dine-In'),
      tableNumber: orderData['tableNumber'] ?? '',
      deliveryAddress: orderData['deliveryAddress'] ?? '',
      pickupTime: null, // Sesuaikan jika ada data pickupTime dari API
      paymentDetails: {
        'method': 'Cash', // Sesuaikan dengan data payment dari API
        'status': 'Paid'  // Sesuaikan dengan data payment dari API
      },
      subtotal: subtotal,
      discount: discount,
      total: total,
      voucherCode: orderData['voucher'] != null ? orderData['voucher']['code'] : null,
      orderTime: orderData['createdAt'] != null
          ? DateTime.parse(orderData['createdAt'])
          : DateTime.now(),
      status: getOrderStatus(orderData['status'] ?? 'Pending'),
    );
  }
}