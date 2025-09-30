import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/voucher_item.dart';

class VoucherService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  /// Ambil list voucher dari API
  Future<List<Voucher>> fetchVouchers({String? userId}) async {
    try {
      // Build query parameters
      final queryParams = {
        'isActive': 'true',
        'validNow': 'true',
        if (userId != null) 'userId': userId,
      };

      final uri = Uri.parse('$baseUrl/api/vouchers/available')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> vouchersJson = data['vouchers'];
        return vouchersJson.map((e) => Voucher.fromJson(e)).toList();
      } else {
        throw Exception("Failed to load vouchers");
      }
    } catch (e) {
      throw Exception("Error fetching vouchers: $e");
    }
  }

  /// Mark voucher sebagai sudah digunakan
  Future<bool> markVoucherAsUsed(String voucherCode, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/vouchers/mark-used'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'voucherCode': voucherCode,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to mark voucher as used");
      }
    } catch (e) {
      throw Exception("Error marking voucher as used: $e");
    }
  }

  /// Validasi voucher sebelum digunakan
  Future<Map<String, dynamic>> validateVoucher({
    required String code,
    required double orderAmount,
    String? userId,
    String? outletId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/vouchers/validate'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'code': code,
          'orderAmount': orderAmount,
          if (userId != null) 'userId': userId,
          if (outletId != null) 'outletId': outletId,
        }),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      throw Exception("Error validating voucher: $e");
    }
  }
}