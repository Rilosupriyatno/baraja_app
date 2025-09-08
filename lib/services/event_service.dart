import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class EventService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<List<Event>> fetchEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/event/'),
      headers: {
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List events = data['data']; // sesuai struktur JSON kamu
      return events.map((e) => Event.fromJson(e)).toList();
    } else {
      throw Exception("Gagal memuat event");
    }
  }
}
