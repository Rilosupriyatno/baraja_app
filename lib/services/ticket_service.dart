import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TicketService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<Map<String, dynamic>> buyTicket({
    required String eventId,
    required String userId,
    required int quantity,
    String paymentMethod = "bank_transfer", // konsisten dengan UI
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

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/ticket/buy"),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode({
          "eventId": eventId,
          "userId": userId,
          "quantity": quantity,
          "paymentMethod": paymentMethod,
        }),
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
            errorMessage = responseBody["message"] ?? "Data yang dikirim tidak valid";
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

  // Method tambahan untuk mendapatkan detail tiket
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody["message"] ?? "Gagal mengambil data tiket");
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