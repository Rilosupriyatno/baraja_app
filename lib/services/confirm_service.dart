import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class ConfirmService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<Map<String, dynamic>> sendOrder(Order order) async {
    try {
      final String? paymentType = order.paymentDetails['methodName'];
      final Map<String, dynamic> paymentData = {
        "payment_type": paymentType,
        "transaction_details": {
          "order_id": order.id,
          "gross_amount": order.total,
        },
      };

      // Tambahkan field tambahan tergantung payment type
      if (paymentType == 'bank_transfer') {
        paymentData['bank_transfer'] = {
          "bank": order.paymentDetails['bankCode'],
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/charge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Success: $responseData");
        return responseData;
      } else {
        print("Failed to send order. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        throw Exception("Gagal memproses pembayaran: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending order: $e");
      throw Exception("Terjadi kesalahan: $e");
    }
  }
}