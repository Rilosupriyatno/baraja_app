// services/reservation_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/area.dart';
import '../models/table.dart';

class ReservationService {
  static String? baseUrl = dotenv.env['BASE_URL'];

  // Get all areas with tables
  static Future<List<Area>> getAreas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/areas'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          return data.map((area) => Area.fromJson(area)).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load areas');
        }
      } else {
        throw Exception('Failed to load areas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching areas: $e');
      throw Exception('Error fetching areas: $e');
    }
  }

  // Get tables for specific area
  static Future<Map<String, dynamic>> getAreaTables(String areaId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/areas/$areaId/tables'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];
          return {
            'area': Area.fromJson(data['area']),
            'tables': (data['tables'] as List)
                .map((table) => TableModel.fromJson(table))
                .toList(),
          };
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load tables');
        }
      } else {
        throw Exception('Failed to load tables: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching area tables: $e');
      throw Exception('Error fetching area tables: $e');
    }
  }

  // Check availability for area with specific tables
  static Future<Map<String, dynamic>> checkAvailability({
    required String date,
    required String time,
    required String areaId,
    required int guestCount,
    List<String>? tableIds, // Optional table IDs parameter
  }) async {
    try {
      final Map<String, String> queryParameters = {
        'date': date,
        'time': time,
        'area_id': areaId,
        'guest_count': guestCount.toString(),
      };

      // Add table IDs to query parameters if provided
      if (tableIds != null && tableIds.isNotEmpty) {
        queryParameters['table_ids'] = tableIds.join(',');
      }

      final Uri url = Uri.parse('$baseUrl/api/areas/availability').replace(
        queryParameters: queryParameters,
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        return {
          'available': responseData['available'] ?? false,
          'message': responseData['message'] ?? '',
          'data': responseData['data'],
          'reason': responseData['reason'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'available': false,
          'message': errorData['message'] ?? 'Failed to check availability',
          'data': null,
          'reason': 'server_error',
        };
      }
    } catch (e) {
      print('Error checking availability: $e');
      return {
        'available': false,
        'message': 'Error checking availability: $e',
        'data': null,
        'reason': 'network_error',
      };
    }
  }

  // Create reservation with selected tables
  static Future<Map<String, dynamic>> createReservation({
    required String date,
    required String time,
    required String areaId,
    required int guestCount,
    required List<String> tableIds,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'date': date,
        'time': time,
        'area_id': areaId,
        'guest_count': guestCount,
        'table_ids': tableIds,
        if (customerName != null) 'customer_name': customerName,
        if (customerPhone != null) 'customer_phone': customerPhone,
        if (notes != null) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/reservations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create reservation');
      }
    } catch (e) {
      print('Error creating reservation: $e');
      throw Exception('Error creating reservation: $e');
    }
  }

  // Get area statistics
  static Future<Map<String, dynamic>> getAreaStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/areas/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to load area stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching area stats: $e');
      throw Exception('Error fetching area stats: $e');
    }
  }
}