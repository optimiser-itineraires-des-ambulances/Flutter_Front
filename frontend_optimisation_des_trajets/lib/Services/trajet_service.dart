import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trajet.dart'; // Adjust the path if your model is elsewhere

class TrajetService {
  static const String _baseUrl = 'http://localhost:8089';

  static Future<List<Trajet>> fetchTrajets() async {
    final response = await http.get(Uri.parse('$_baseUrl/trajet/all'));

    if (response.statusCode == 200) {
      final List<dynamic> trajetJson = json.decode(response.body);
      return trajetJson.map((json) => Trajet.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load trajets');
    }
  }
}
