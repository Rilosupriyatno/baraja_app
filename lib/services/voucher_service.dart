import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/voucher_item.dart';

class VoucherService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  /// Ambil list voucher dari API
  Future<List<Voucher>> fetchVouchers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/vouchers/available'),
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
}
