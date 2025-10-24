// services/gro_service.dart - Updated version
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GROService {
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

      // ✅ PERBAIKAN: Jangan kirim status jika 'all' atau null
      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }

      if (date != null) queryParams['date'] = date;
      if (areaId != null) queryParams['area_id'] = areaId;
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/api/gro/reservations').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print("ini adalah response: $responseData");
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
        Uri.parse('$baseUrl/api/gro/reservations/$id'),
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

  // Get dine-in order detail (dengan prefix /gro/)
  Future<Map<String, dynamic>> getDineInOrderDetail(String orderId) async {
    try {
      final headers = await _getHeaders();

      // ✅ Gunakan /api/gro/orders/ (bukan /api/orders/)
      final url = '$baseUrl/api/gro/orders/$orderId';

      print('🔍 Fetching order detail for ID: $orderId');
      print('🔍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        print('📦 Response type: ${responseData.runtimeType}');

        // Pastikan response adalah Map
        if (responseData is! Map<String, dynamic>) {
          print('❌ Invalid response format');
          return {
            'success': false,
            'error': 'Invalid response format: expected Map but got ${responseData.runtimeType}',
          };
        }

        final Map<String, dynamic> data = responseData;

        // Cek apakah success = false (order tidak ditemukan)
        if (data['success'] == false) {
          print('❌ Order not found or error');
          return {
            'success': false,
            'error': data['message'] ?? 'Order tidak ditemukan',
          };
        }

        // Cek apakah ada key 'data'
        if (!data.containsKey('data')) {
          print('❌ No data field in response');
          return {
            'success': false,
            'error': 'Response does not contain data field',
          };
        }

        // Cek jika data adalah array kosong
        if (data['data'] is List && (data['data'] as List).isEmpty) {
          print('❌ Data is empty array');
          return {
            'success': false,
            'error': 'Order tidak ditemukan atau sudah tidak aktif',
          };
        }

        // Pastikan data['data'] adalah Map
        if (data['data'] is! Map<String, dynamic>) {
          print('❌ Data field is not a Map: ${data['data'].runtimeType}');
          return {
            'success': false,
            'error': 'Data field is not a Map: ${data['data'].runtimeType}',
          };
        }

        print('✅ Order detail loaded successfully');
        return {
          'success': true,
          'data': data['data'] as Map<String, dynamic>,
        };
      } else if (response.statusCode == 404) {
        print('❌ Order not found (404)');
        return {
          'success': false,
          'error': 'Order tidak ditemukan',
        };
      } else {
        print('❌ Error response: ${response.statusCode}');
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['message'] ?? 'Gagal memuat detail order',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Gagal memuat detail order (${response.statusCode})',
          };
        }
      }
    } catch (e, stackTrace) {
      print('❌ Exception in getDineInOrderDetail: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ✅ TAMBAHAN METHOD BARU: Get order detail with payment info (seperti tracking)
  Future<Map<String, dynamic>> getOrderDetailWithPayment(String orderId) async {
    try {
      final headers = await _getHeaders();

      // Gunakan endpoint yang sama seperti di tracking
      final url = '$baseUrl/api/order/$orderId';

      print('🔍 Fetching order detail for ID: $orderId');
      print('🔍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is! Map<String, dynamic>) {
          return {
            'success': false,
            'error': 'Invalid response format',
          };
        }

        final Map<String, dynamic> data = responseData;

        // Check if order data exists
        if (!data.containsKey('orderData')) {
          return {
            'success': false,
            'error': 'Order data not found in response',
          };
        }

        // Pastikan orderData adalah Map
        if (data['orderData'] is! Map<String, dynamic>) {
          return {
            'success': false,
            'error': 'Invalid order data format',
          };
        }

        print('✅ Order detail with payment loaded successfully');
        return {
          'success': true,
          'data': data['orderData'] as Map<String, dynamic>,
        };
      } else if (response.statusCode == 404) {
        print('❌ Order not found (404)');
        return {
          'success': false,
          'error': 'Order tidak ditemukan',
        };
      } else {
        print('❌ Error response: ${response.statusCode}');
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['message'] ?? 'Gagal memuat detail order',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Gagal memuat detail order (${response.statusCode})',
          };
        }
      }
    } catch (e, stackTrace) {
      print('❌ Exception in getOrderDetailWithPayment: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Confirm reservation
  Future<Map<String, dynamic>> confirmReservation(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/gro/reservations/$id/confirm'),
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
        Uri.parse('$baseUrl/api/gro/reservations/$id/check-in'),
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

// ✅ TAMBAHAN di gro_service.dart

// Check-in dine-in order (Reserved → OnProcess)
  Future<Map<String, dynamic>> checkInDineInOrder(String orderId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/gro/orders/$orderId/dine-in/check-in'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Customer berhasil check-in',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal check-in customer',
        };
      }
    } catch (e) {
      print('Error checking in dine-in order: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

// Cancel dine-in order (Reserved → Canceled)
  Future<Map<String, dynamic>> cancelDineInOrder(
      String orderId, {
        String? reason,
      }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/gro/orders/$orderId/cancel'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Order berhasil dibatalkan',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal membatalkan order',
        };
      }
    } catch (e) {
      print('Error canceling dine-in order: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ✅ Check-out dine-in customer
  Future<Map<String, dynamic>> checkOutDineInOrder(String orderId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/gro/orders/$orderId/dine-in/check-out'),
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
      print('Error checking out dine-in order: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // ✅ Complete dine-in order
  Future<Map<String, dynamic>> completeDineInOrder(String orderId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/gro/orders/$orderId/complete'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Order berhasil diselesaikan',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal menyelesaikan order',
        };
      }
    } catch (e) {
      print('Error completing dine-in order: $e');
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
        Uri.parse('$baseUrl/api/gro/reservations/$id/check-out'),
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
        Uri.parse('$baseUrl/api/gro/reservations/$id/complete'),
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
        Uri.parse('$baseUrl/api/gro/reservations/$id/cancel'),
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
        Uri.parse('$baseUrl/api/gro/reservations/$id/transfer-table'),
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

  Future<Map<String, dynamic>> getDashboardStats({String? date}) async {
    try {
      final headers = await _getHeaders();

      final queryParams = <String, String>{};
      if (date != null) queryParams['date'] = date;

      final uri = Uri.parse('$baseUrl/api/gro/dashboard-stats').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(uri, headers: headers);

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

      final uri = Uri.parse('$baseUrl/api/gro/tables/availability').replace(
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

  // ✅ METHOD BARU: Force reset table status
  Future<Map<String, dynamic>> forceResetTableStatus(String tableNumber) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/gro/tables/$tableNumber/force-reset'),
        headers: headers,
      );

      print('Force reset response status: ${response.statusCode}');
      print('Force reset response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Table status berhasil direset',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal reset status meja',
        };
      }
    } catch (e) {
      print('Error force resetting table: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> syncTableStatus(String outletId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/api/gro/tables/sync-status'),
        headers: headers,
        body: json.encode({'outletId': outletId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to sync table status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error syncing table status: $e');
      throw Exception('Error syncing table status: $e');
    }
  }

// Debug table status
  Future<Map<String, dynamic>> debugTableStatus(String outletId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/api/gro/tables/debug-status'),
        headers: headers,
        body: json.encode({'outletId': outletId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to debug table status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error debugging table status: $e');
      throw Exception('Error debugging table status: $e');
    }
  }

// Reset table status
  Future<Map<String, dynamic>> resetTableStatus(String tableId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/gro/tables/$tableId/reset-status'),
        headers: headers,
        body: json.encode({'status': 'available'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to reset table status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error resetting table status: $e');
      throw Exception('Error resetting table status: $e');
    }
  }

  Future<Map<String, dynamic>> getTableOrderDetail({
    required String tableNumber,
    required String date,
  }) async {
    try {
      final headers = await _getHeaders();

      final uri = Uri.parse('$baseUrl/api/gro/tables/$tableNumber/order').replace(
        queryParameters: {'date': date},
      );

      print('🔍 Fetching table order detail for table: $tableNumber, date: $date');
      print('🔍 URL: ${uri.toString()}');

      final response = await http.get(uri, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // ✅ JIKA 404, COBA SYNC DULU KEMUDI RETRY
      if (response.statusCode == 404) {
        print('🔄 Order not found, syncing table status and retrying...');

        // Sync table status terlebih dahulu
        await syncTableStatus("67cbc9560f025d897d69f889"); // Ganti dengan outletId yang sesuai

        // Tunggu sebentar untuk memastikan sync selesai
        await Future.delayed(const Duration(seconds: 1));

        // Coba lagi
        final retryResponse = await http.get(uri, headers: headers);

        if (retryResponse.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(retryResponse.body);

          if (responseData['success'] == false) {
            print('❌ Still no order after sync');
            return {
              'success': false,
              'error': responseData['message'] ?? 'Tidak ada data order',
              'data': null,
            };
          }

          print('✅ Order found after sync!');
          return {
            'success': true,
            'data': responseData['data'],
          };
        }
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Validasi response structure
        if (responseData['success'] == false) {
          print('❌ API returned success: false');
          return {
            'success': false,
            'error': responseData['message'] ?? 'Tidak ada data order',
            'data': null,
          };
        }

        // Jika success true tapi data kosong
        if (responseData['data'] == null ||
            (responseData['data'] is Map && responseData['data'].isEmpty) ||
            (responseData['data'] is List && responseData['data'].isEmpty)) {
          print('⚠️ Data is empty or null');
          return {
            'success': false,
            'error': 'Tidak ada data order untuk meja ini',
            'data': null,
          };
        }

        print('✅ Table order detail loaded successfully');
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        print('❌ Error response: ${response.statusCode}');
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['message'] ?? 'Gagal memuat detail order',
            'data': null,
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Gagal memuat detail order (${response.statusCode})',
            'data': null,
          };
        }
      }
    } catch (e, stackTrace) {
      print('❌ Exception in getTableOrderDetail: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
        'data': null,
      };
    }
  }

  // Complete table order (finish order and make table available)
  Future<Map<String, dynamic>> completeTableOrder(String orderId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/gro/orders/$orderId/complete'),
        headers: headers,
      );

      print('Complete order response status: ${response.statusCode}');
      print('Complete order response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Order berhasil diselesaikan',
          'data': responseData['data'],
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Gagal menyelesaikan order',
        };
      }
    } catch (e) {
      print('Error completing order: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Close open bill
  Future<Map<String, dynamic>> closeOpenBill(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/api/gro/reservations/$id/close-open-bill'),
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