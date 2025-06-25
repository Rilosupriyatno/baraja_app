import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class ConfirmService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<PaymentResult> sendOrder(Order order) async {
    try {
      final String? paymentType = order.paymentDetails['methodName'];

      // Untuk cash payment, gunakan struktur yang lebih sederhana
      Map<String, dynamic> paymentData;

      if (paymentType == 'cash') {
        paymentData = {
          "payment_type": paymentType,
          "order_id": order.orderId,
          "gross_amount": order.total,
        };
      } else {
        // Untuk payment type lainnya (bank_transfer, gopay, qris, dll)
        paymentData = {
          "payment_type": paymentType,
          "transaction_details": {
            "order_id": order.orderId,
            "gross_amount": order.total,
          },
        };

        // Tambahkan field tambahan tergantung payment type
        if (paymentType == 'bank_transfer') {
          paymentData['bank_transfer'] = {
            "bank": order.paymentDetails['bankCode'],
          };
        }
      }

      _printRequestData(paymentData);

      final response = await http.post(
        Uri.parse('$baseUrl/api/charge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(paymentData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic>? responseData;

        // Parse response body jika tidak kosong
        if (response.body.isNotEmpty) {
          try {
            responseData = json.decode(response.body);
          } catch (e) {
            print('Warning: Failed to parse response body as JSON: $e');
          }
        }

        _printSuccessResponse(responseData ?? {});

        return PaymentResult(
          success: true,
          message: paymentType == 'cash'
              ? 'Pembayaran tunai berhasil diproses'
              : 'Pembayaran berhasil diproses',
          data: responseData,
        );
      } else {
        _printErrorResponse(response);

        // Handle error response
        String errorMessage = paymentType == 'cash'
            ? 'Gagal memproses pembayaran tunai'
            : 'Gagal memproses pembayaran';

        if (response.body.isNotEmpty) {
          try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            errorMessage = 'Error ${response.statusCode}: ${response.body}';
          }
        } else {
          errorMessage = 'Error ${response.statusCode}: ${response.reasonPhrase}';
        }

        return PaymentResult(
          success: false,
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (error) {
      _printException(error);

      String errorMessage = 'Terjadi kesalahan saat memproses pembayaran';

      // Customize error message berdasarkan jenis error
      if (error.toString().contains('SocketException')) {
        errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (error.toString().contains('TimeoutException')) {
        errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      } else if (error.toString().contains('FormatException')) {
        errorMessage = 'Terjadi kesalahan dalam format data.';
      }

      return PaymentResult(
        success: false,
        message: errorMessage,
        error: error.toString(),
      );
    }
  }

  // Helper method untuk print request data
  void _printRequestData(Map<String, dynamic> paymentData) {
    print('\n${'=' * 50}');
    print('📤 SENDING PAYMENT REQUEST');
    print('=' * 50);
    print('🔹 Payment Type: ${paymentData['payment_type']}');

    if (paymentData.containsKey('transaction_details')) {
      print('🔹 Order ID: ${paymentData['transaction_details']['order_id']}');
      print('🔹 Amount: ${paymentData['transaction_details']['gross_amount']}');
    } else {
      print('🔹 Order ID: ${paymentData['order_id']}');
      print('🔹 Amount: ${paymentData['gross_amount']}');
    }

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

/// Class untuk menampung hasil dari API call
class PaymentResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final int? statusCode;
  final String? error;

  PaymentResult({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.error,
  });

  @override
  String toString() {
    return 'PaymentResult(success: $success, message: $message, data: $data, statusCode: $statusCode, error: $error)';
  }
}