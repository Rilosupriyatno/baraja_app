import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TicketService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  // ✅ ENHANCED: Create ticket payment with proper validation
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
      final orderId = 'TICKET-$eventId';

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

      // Add payment method specific data
      if (paymentMethod == 'bank_transfer' && bankCode != null) {
        paymentData["bank_transfer"] = {"bank": bankCode};
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

      if (response.statusCode == 200) {
        // ✅ ENHANCED: Validate response structure

        print("ini adalah response dari chargeTicket : $responseBody");
        if (responseBody['success'] != null && responseBody['success'] == false) {
          throw Exception(responseBody['message'] ?? 'Pembelian tiket gagal');
        }
        return responseBody;
      } else {
        String errorMessage = responseBody["message"] ?? "Gagal memproses pembayaran tiket";
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga: ${e.toString()}');
      }
    }
  }

  // ✅ ENHANCED: Get user tickets with better error handling
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

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Handle the enhanced API response structure
        debugPrint(
          const JsonEncoder.withIndent('  ').convert(responseBody),
          wrapWidth: 1024,
        );
        if (responseBody is Map<String, dynamic> &&
            responseBody['success'] == true &&
            responseBody['data'] is List) {
          final List<dynamic> data = responseBody['data'];
          return data.cast<Map<String, dynamic>>();
        } else if (responseBody is List) {
          return responseBody.cast<Map<String, dynamic>>();
        } else {
          throw Exception("Format response tidak sesuai");
        }
      } else {
        throw Exception(responseBody["message"] ?? "Gagal mengambil data tiket");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga: ${e.toString()}');
      }
    }
  }

  // ✅ NEW: Get ticket by code
  Future<Map<String, dynamic>> getTicketByCode(String ticketCode) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/ticket/code/$ticketCode"),
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
        if (responseBody['success'] == true) {
          return responseBody['data'];
        } else {
          throw Exception(responseBody['message'] ?? "Tiket tidak ditemukan");
        }
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody["message"] ?? "Gagal mengambil data tiket");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga: ${e.toString()}');
      }
    }
  }

  // ✅ NEW: Validate ticket for check-in
  Future<Map<String, dynamic>> validateTicket(String ticketCode, String checkedInBy) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/ticket/validate/$ticketCode"),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode({
          "checkedInBy": checkedInBy,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody;
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody["message"] ?? "Gagal validasi tiket");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga: ${e.toString()}');
      }
    }
  }

  // ✅ ENHANCED: Get payment status with better error handling
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
        final responseBody = jsonDecode(response.body);
        return responseBody;
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(
            responseBody["message"] ?? "Gagal mengambil status pembayaran");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga: ${e.toString()}');
      }
    }
  }

  // ✅ NEW: Update ticket status
  Future<Map<String, dynamic>> updateTicketStatus({
    required String ticketId,
    required String status,
    String? checkedInBy,
  }) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    try {
      final requestBody = <String, dynamic>{
        "status": status,
      };

      if (checkedInBy != null) {
        requestBody["checkedInBy"] = checkedInBy;
      }

      final response = await http.patch(
        Uri.parse("$baseUrl/api/ticket/$ticketId/status"),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody;
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody["message"] ?? "Gagal update status tiket");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga: ${e.toString()}');
      }
    }
  }

  // ✅ NEW: Check event ticket availability
  Future<Map<String, dynamic>> checkEventAvailability(String eventId) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/ticket/event/$eventId/availability"),
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
        return responseBody;
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody["message"] ?? "Gagal cek ketersediaan tiket");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga: ${e.toString()}');
      }
    }
  }

  // ✅ NEW: Get event tickets for organizers
  Future<Map<String, dynamic>> getEventTickets({
    required String eventId,
    String? status,
    String? paymentStatus,
  }) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    try {
      String url = "$baseUrl/api/ticket/event/$eventId";

      // Add query parameters
      List<String> params = [];
      if (status != null) params.add("status=$status");
      if (paymentStatus != null) params.add("paymentStatus=$paymentStatus");

      if (params.isNotEmpty) {
        url += "?${params.join("&")}";
      }

      final response = await http.get(
        Uri.parse(url),
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
        return responseBody;
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody["message"] ?? "Gagal mengambil data tiket event");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga: ${e.toString()}');
      }
    }
  }

  // ✅ NEW: Refresh ticket status (untuk sync dengan server)
  Future<Map<String, dynamic>> refreshTicketStatus(String ticketId) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/ticket/$ticketId/refresh"),
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
        return responseBody;
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody["message"] ?? "Gagal refresh status tiket");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga: ${e.toString()}');
      }
    }
  }

  // ✅ NEW: Cancel ticket purchase
  Future<Map<String, dynamic>> cancelTicket(String ticketId, String reason) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Konfigurasi server tidak ditemukan');
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/ticket/$ticketId/cancel"),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode({
          "reason": reason,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody;
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody["message"] ?? "Gagal membatalkan tiket");
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan yang tidak terduga: ${e.toString()}');
      }
    }
  }

  // ✅ UTILITY: Check if ticket can be cancelled
  bool canCancelTicket(Map<String, dynamic> ticket) {
    final status = ticket['status'];
    // final paymentStatus = ticket['payment']?['status'];

    // Can cancel if ticket is pending or confirmed but event hasn't started
    if (status == 'pending') return true;
    if (status == 'used' || status == 'cancelled') return false;

    if (status == 'confirmed') {
      final eventDate = DateTime.tryParse(ticket['event']?['date'] ?? '');
      if (eventDate != null) {
        final now = DateTime.now();
        // Allow cancellation up to 24 hours before event
        return eventDate.difference(now).inHours > 24;
      }
    }

    return false;
  }

  // ✅ UTILITY: Check if ticket can be used
  bool canUseTicket(Map<String, dynamic> ticket) {
    final status = ticket['status'];
    final paymentStatus = ticket['payment']?['status'];
    final isPaid = ['settlement', 'paid'].contains(paymentStatus);

    return status == 'confirmed' && isPaid;
  }

  // ✅ UTILITY: Get ticket status display text
  String getTicketStatusText(String status, String? paymentStatus) {
    switch (status) {
    case 'settlement':
    case 'capture':
    case 'paid':
    case 'Paid':
      return 'Lunas';
    case 'partial':
      return 'Menunggu Pelunasan';
    case 'pending':
      return 'Menunggu Pembayaran';
    case 'expire':
    case 'Unpaid':
      return 'Kadaluarsa';
    case 'cancel':
      return 'Dibatalkan';
    case 'deny':
      return  'Ditolak';
    case 'failure':
      return  'Gagal';
    default:
    return  'Status Tidak Diketahui';
    }
  }
}