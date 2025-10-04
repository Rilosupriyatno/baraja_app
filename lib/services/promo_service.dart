import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/promo_item.dart';

class PromoService {
  static String? baseUrl = dotenv.env['BASE_URL'];

  static Future<List<PromoItem>> fetchPromos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/content'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => PromoItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load promos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching promos: $e');
      return [];
    }
  }
}
