import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TicketService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<Map<String, dynamic>> buyTicket({
    required String eventId,
    required String userId,
    required int quantity,
    required String paymentMethod, // Now required and specific
    String? bankCode, // Optional bank code for bank transfers
    String? paymentMethodName, // Display name of payment method
  }) async {
    // Validasi base URL
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    // Validasi input
    if (eventId.isEmpty) {
      throw Exception('ID event tidak valid');
    }

    if (userId.isEmpty) {
      throw Exception('ID user tidak valid');
    }

    if (quantity <= 0) {
      throw Exception('Jumlah tiket harus lebih dari 0');
    }

    if (paymentMethod.isEmpty) {
      throw Exception('Metode pembayaran harus dipilih');
    }

    try {
      // Prepare payment data based on method
      Map<String, dynamic> paymentData = {
        "eventId": eventId,
        "userId": userId,
        "quantity": quantity,
        "paymentMethod": paymentMethod,
      };

      // Add additional payment method specific data
      if (paymentMethodName != null && paymentMethodName.isNotEmpty) {
        paymentData["paymentMethodName"] = paymentMethodName;
      }

      if (bankCode != null && bankCode.isNotEmpty) {
        paymentData["bankCode"] = bankCode;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/ticket/buy"),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode(paymentData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Koneksi timeout. Silakan coba lagi.');
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseBody;
      } else {
        // Handle different error status codes
        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage =
                responseBody["message"] ?? "Data yang dikirim tidak valid";
            break;
          case 401:
            errorMessage = "Anda harus login terlebih dahulu";
            break;
          case 404:
            errorMessage = "Event tidak ditemukan";
            break;
          case 409:
            errorMessage = responseBody["message"] ?? "Tiket sudah habis";
            break;
          case 500:
            errorMessage = "Terjadi kesalahan server. Silakan coba lagi nanti.";
            break;
          default:
            errorMessage = responseBody["message"] ?? "Gagal membeli tiket";
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga');
      }
    }
  }

  // Enhanced method for creating ticket payment with Midtrans integration
  Future<Map<String, dynamic>> createTicketPayment({
    required String eventId,
    required String userId,
    required int quantity,
    required int totalAmount,
    required String paymentMethod,
    String? bankCode,
    String? paymentMethodName,
  }) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    try {
      // Generate unique order ID for the ticket purchase
      final timestamp = DateTime
          .now()
          .millisecondsSinceEpoch;
      final orderId = 'TICKET-$eventId-$userId-$timestamp';

      final paymentData = {
        "payment_type": paymentMethod,
        "transaction_details": {
          "order_id": orderId,
          "gross_amount": totalAmount,
        },
        "event_id": eventId,
        "user_id": userId,
        "quantity": quantity,
      };

      // Add bank transfer specific data
      if (paymentMethod == 'bank_transfer' && bankCode != null) {
        paymentData["bank_transfer"] = {"bank": bankCode};
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/ticket/buy"),
        // New endpoint for ticket payments
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode(paymentData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Koneksi timeout. Silakan coba lagi.');
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        String errorMessage = responseBody["message"] ??
            "Gagal memproses pembayaran tiket";
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga');
      }
    }
  }

  // Method untuk mendapatkan detail tiket user (updated to handle the API response structure)
  Future<List<Map<String, dynamic>>> getUserTickets(String userId) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/ticket/user/$userId"),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Handle the API response structure
        if (responseBody is Map<String, dynamic> &&
            responseBody['success'] == true &&
            responseBody['data'] is List) {
          final List<dynamic> data = responseBody['data'];
          return data.cast<Map<String, dynamic>>();
        } else if (responseBody is List) {
          // Handle if response is directly a list
          return responseBody.cast<Map<String, dynamic>>();
        } else {
          throw Exception("Format response tidak sesuai");
        }
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(
            responseBody["message"] ?? "Gagal mengambil data tiket");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga');
      }
    }
  }

  // Method untuk mendapatkan status pembayaran tiket
  Future<Map<String, dynamic>> getTicketPaymentStatus(String paymentId) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/payment/status/$paymentId"),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(
            responseBody["message"] ?? "Gagal mengambil status pembayaran");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga');
      }
    }
  }
}