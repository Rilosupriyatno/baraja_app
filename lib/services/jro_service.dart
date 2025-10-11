// services/jro_service.dart - Updated version
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JROService {
  static String? baseUrl = dotenv.env['BASE_URL'];

  // Get auth token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Create reservation (updated to match backend)
  Future<Map<String, dynamic>> createReservation({
    required String guestName,
    required String guestPhone,
    required int guestCount,
    required String reservationDate,
    required String reservationTime,
    required List<String> tableIds,
    required String areaId,
    String? notes,
    String? outlet,
    List<Map<String, dynamic>>? items,
    String? voucherCode,
    String reservationType = 'nonBlocking',
    bool servingFood = false,
    List<String>? equipment,
    String foodServingOption = 'immediate',
    String? foodServingTime,
  }) async {
    try {
      final headers = await _getHeaders();

      final Map<String, dynamic> requestBody = {
        'guest_name': guestName,
        'guest_phone': guestPhone,
        'guest_count': guestCount,
        'reservation_date': reservationDate,
        'reservation_time': reservationTime,
        'table_ids': tableIds,
        'area_id': areaId,
        'reservation_type': reservationType,
        'serving_food': servingFood,
        'food_serving_option': foodServingOption,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (outlet != null) 'outlet': outlet,
        if (items != null && items.isNotEmpty) 'items': items,
        if (voucherCode != null && voucherCode.isNotEmpty) 'voucherCode': voucherCode,
        if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
        if (foodServingTime != null) 'food_serving_time': foodServingTime,
      };

      print('Creating reservation with data: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/api/jro/reservations'),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Reservasi berhasil dibuat',
          'data': responseData['data'],
          'order': responseData['order'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal membuat reservasi',
        };
      }
    } catch (e) {
      print('Error creating reservation: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Get all reservations with filters
  Future<Map<String, dynamic>> getReservations({
    int page = 1,
    int limit = 20,
    String? status,
    String? date,
    String? areaId,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) queryParams['status'] = status;
      if (date != null) queryParams['date'] = date;
      if (areaId != null) queryParams['area_id'] = areaId;
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/api/jro/reservations').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to load reservations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reservations: $e');
      throw Exception('Error fetching reservations: $e');
    }
  }

  // Get single reservation detail
  Future<Map<String, dynamic>> getReservationDetail(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/jro/reservations/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to load reservation detail: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reservation detail: $e');
      throw Exception('Error fetching reservation detail: $e');
    }
  }

  // Confirm reservation
  Future<Map<String, dynamic>> confirmReservation(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/confirm'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Reservasi berhasil dikonfirmasi',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal mengkonfirmasi reservasi',
        };
      }
    } catch (e) {
      print('Error confirming reservation: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Check-in reservation
  Future<Map<String, dynamic>> checkInReservation(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/check-in'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Check-in berhasil',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal check-in',
        };
      }
    } catch (e) {
      print('Error checking in reservation: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Check-out reservation
  Future<Map<String, dynamic>> checkOutReservation(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/check-out'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Check-out berhasil',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal check-out',
        };
      }
    } catch (e) {
      print('Error checking out reservation: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Complete reservation
  Future<Map<String, dynamic>> completeReservation(
      String id, {
        bool closeOpenBill = false,
      }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/complete'),
        headers: headers,
        body: json.encode({'closeOpenBill': closeOpenBill}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Reservasi selesai',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal menyelesaikan reservasi',
        };
      }
    } catch (e) {
      print('Error completing reservation: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Cancel reservation
  Future<Map<String, dynamic>> cancelReservation(
      String id, {
        String? reason,
      }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/cancel'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Reservasi dibatalkan',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal membatalkan reservasi',
        };
      }
    } catch (e) {
      print('Error canceling reservation: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Transfer table
  Future<Map<String, dynamic>> transferTable(
      String id, {
        required List<String> newTableIds,
        String? reason,
      }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/transfer-table'),
        headers: headers,
        body: json.encode({
          'new_table_ids': newTableIds,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Meja berhasil dipindahkan',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal memindahkan meja',
        };
      }
    } catch (e) {
      print('Error transferring table: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/jro/dashboard-stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      throw Exception('Error fetching dashboard stats: $e');
    }
  }

  // Get table availability
  Future<Map<String, dynamic>> getTableAvailability({
    String? date,
    String? time,
    String? areaId,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = <String, String>{};
      if (date != null) queryParams['date'] = date;
      if (time != null) queryParams['time'] = time;
      if (areaId != null) queryParams['area_id'] = areaId;

      final uri = Uri.parse('$baseUrl/api/jro/tables/availability').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to load table availability: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching table availability: $e');
      throw Exception('Error fetching table availability: $e');
    }
  }

  // Close open bill
  Future<Map<String, dynamic>> closeOpenBill(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/close-open-bill'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Open bill berhasil ditutup',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal menutup open bill',
        };
      }
    } catch (e) {
      print('Error closing open bill: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }
}