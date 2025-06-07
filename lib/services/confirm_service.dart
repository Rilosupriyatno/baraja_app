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

      _printRequestData(paymentData);

      final response = await http.post(
        Uri.parse('$baseUrl/api/charge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _printSuccessResponse(responseData);
        return responseData;
      } else {
        _printErrorResponse(response);
        throw Exception("Gagal memproses pembayaran: ${response.statusCode}");
      }
    } catch (e) {
      _printException(e);
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  // Helper method untuk print request data
  void _printRequestData(Map<String, dynamic> paymentData) {
    print('\n${'=' * 50}');
    print('📤 SENDING PAYMENT REQUEST');
    print('=' * 50);
    print('🔹 Payment Type: ${paymentData['payment_type']}');
    print('🔹 Order ID: ${paymentData['transaction_details']['order_id']}');
    print('🔹 Amount: ${paymentData['transaction_details']['gross_amount']}');

    if (paymentData.containsKey('bank_transfer')) {
      print('🔹 Bank: ${paymentData['bank_transfer']['bank']}');
    }

    print('\n📋 Full Request Data:');
    print(const JsonEncoder.withIndent('  ').convert(paymentData));
    print('${'=' * 50}\n');
  }

  // Helper method untuk print success response
  void _printSuccessResponse(Map<String, dynamic> responseData) {
    print('\n${'=' * 50}');
    print('✅ PAYMENT REQUEST SUCCESS');
    print('=' * 50);

    // Print informasi penting dari response
    if (responseData.containsKey('transaction_status')) {
      print('🔹 Status: ${responseData['transaction_status']}');
    }
    if (responseData.containsKey('transaction_id')) {
      print('🔹 Transaction ID: ${responseData['transaction_id']}');
    }
    if (responseData.containsKey('order_id')) {
      print('🔹 Order ID: ${responseData['order_id']}');
    }
    if (responseData.containsKey('gross_amount')) {
      print('🔹 Amount: ${responseData['gross_amount']}');
    }

    print('\n📋 Full Response Data:');
    print(const JsonEncoder.withIndent('  ').convert(responseData));
    print('${'=' * 50}\n');
  }

  // Helper method untuk print error response
  void _printErrorResponse(http.Response response) {
    print('\n${'=' * 50}');
    print('❌ PAYMENT REQUEST FAILED');
    print('=' * 50);
    print('🔹 Status Code: ${response.statusCode}');
    print('🔹 Reason: ${response.reasonPhrase}');

    try {
      final errorData = jsonDecode(response.body);
      print('\n📋 Error Details:');
      print(const JsonEncoder.withIndent('  ').convert(errorData));
    } catch (e) {
      print('\n📋 Raw Response Body:');
      print(response.body);
    }

    print('${'=' * 50}\n');
  }

  // Helper method untuk print exception
  void _printException(dynamic error) {
    print('\n${'=' * 50}');
    print('💥 EXCEPTION OCCURRED');
    print('=' * 50);
    print('🔹 Error Type: ${error.runtimeType}');
    print('🔹 Error Message: $error');
    print('${'=' * 50}\n');
  }
}