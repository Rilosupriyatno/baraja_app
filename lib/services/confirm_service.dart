import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart'; // Kalau ada model Order

class ConfirmService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<void> sendOrder(Order order) async {

    try {
      final Map<String, dynamic> paymentData = {
        "payment_type": order.paymentDetails['methodName'],
        "transaction_details": {
          "order_id": order.id,
          "gross_amount": order.total,
        },
        "bank_transfer": {
          "bank": "bca",
        }
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/charge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Success: $responseData");
      } else {
        print("Failed to send order. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error sending order: $e");
    }
  }
}
