import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    required String paymentMethod,
    required String paymentMethodName,
    String? bankName,
    String? bankCode,
    required int subtotal,
    required int discount,
    String? voucherCode,
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
        'paymentDetails': {
          'method': paymentMethod,
          'methodName': paymentMethodName,
          'bankName': bankName,
          'bankCode': bankCode,
        },
        'pricing': {
          'subtotal': subtotal,
          'discount': discount,
          'total': subtotal - discount,
        },
        'voucherCode': voucherCode,
        'orderDate': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

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
}