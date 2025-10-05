import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JROService {
  final String? baseUrl = dotenv.env['BASE_URL'];
  static const Duration requestTimeout = Duration(seconds: 10);

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
        Uri.parse('$baseUrl/api/jro/dashboard-stats'),
        headers: headers,
      )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'data': jsonData['data'],
          'error': null,
        };
      } else {
        return {
          'success': false,
          'data': null,
          'error': 'Failed to load dashboard stats: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Error fetching dashboard stats: $e',
      };
    }
  }

  // Get Reservations with filters
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
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        // Kirim date parameter bahkan jika 'all'
        if (date != null && date.isNotEmpty) 'date': date,
        if (areaId != null && areaId.isNotEmpty) 'area_id': areaId,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('$baseUrl/api/jro/reservations')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'data': jsonData['data'],
          'pagination': jsonData['pagination'],
          'error': null,
        };
      } else {
        return {
          'success': false,
          'data': null,
          'error': 'Failed to load reservations: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Error fetching reservations: $e',
      };
    }
  }

  // Get Reservation Detail
  Future<Map<String, dynamic>> getReservationDetail(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
        Uri.parse('$baseUrl/api/jro/reservations/$id'),
        headers: headers,
      )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'data': jsonData['data'],
          'error': null,
        };
      } else {
        return {
          'success': false,
          'data': null,
          'error': 'Failed to load reservation detail: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Error fetching reservation detail: $e',
      };
    }
  }

  // Confirm Reservation
  Future<Map<String, dynamic>> confirmReservation(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/confirm'),
        headers: headers,
      )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'data': jsonData['data'],
          'message': jsonData['message'],
          'error': null,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'data': null,
          'error': errorData['message'] ?? 'Failed to confirm reservation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Error confirming reservation: $e',
      };
    }
  }

  // Complete Reservation
  Future<Map<String, dynamic>> completeReservation(
      String id, {
        bool closeOpenBill = false,
      }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/complete'),
        headers: headers,
        body: json.encode({'closeOpenBill': closeOpenBill}),
      )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'data': jsonData['data'],
          'message': jsonData['message'],
          'error': null,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'data': null,
          'error': errorData['message'] ?? 'Failed to complete reservation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Error completing reservation: $e',
      };
    }
  }

  // Cancel Reservation
  Future<Map<String, dynamic>> cancelReservation(
      String id, {
        String? reason,
      }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/cancel'),
        headers: headers,
        body: json.encode({'reason': reason}),
      )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'data': jsonData['data'],
          'message': jsonData['message'],
          'error': null,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'data': null,
          'error': errorData['message'] ?? 'Failed to cancel reservation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Error cancelling reservation: $e',
      };
    }
  }

  // Close Open Bill
  Future<Map<String, dynamic>> closeOpenBill(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
        Uri.parse('$baseUrl/api/jro/reservations/$id/close-open-bill'),
        headers: headers,
      )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'data': jsonData['data'],
          'message': jsonData['message'],
          'error': null,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'data': null,
          'error': errorData['message'] ?? 'Failed to close open bill',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Error closing open bill: $e',
      };
    }
  }

  // Get Table Availability
  Future<Map<String, dynamic>> getTableAvailability({
    String? date,
    String? time,
    String? areaId,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        if (date != null && date.isNotEmpty) 'date': date,
        if (time != null && time.isNotEmpty) 'time': time,
        if (areaId != null && areaId.isNotEmpty) 'area_id': areaId,
      };

      final uri = Uri.parse('$baseUrl/api/jro/tables/availability')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'data': jsonData['data'],
          'error': null,
        };
      } else {
        return {
          'success': false,
          'data': null,
          'error': 'Failed to load table availability: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Error fetching table availability: $e',
      };
    }
  }
}