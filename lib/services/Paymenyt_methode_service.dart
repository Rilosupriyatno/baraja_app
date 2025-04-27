import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaymentMethodeService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  PaymentMethodeService();

  // Mengambil data metode pembayaran
  Future<List<Map<String, dynamic>>> fetchPaymentMethods() async {
    final response = await http.get(Uri.parse('$baseUrl/api/paymentlist/payment-methods'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load payment methods');
    }
  }
}
