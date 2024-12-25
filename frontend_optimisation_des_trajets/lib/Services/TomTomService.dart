import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class TomTomService {
  static const String apiKey = 'e1dHfgMxAALVMe7oaMRODCSQLJ4ertc1'; // Replace with your actual API key
  static const String apiUrl =
      'https://api.tomtom.com/routing/1/calculateRoute';

  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
        '$apiUrl/${start.latitude},${start.longitude}:${end.latitude},${end.longitude}/json?key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Check if the response contains valid route data
      if (data != null &&
          data['routes'] != null &&
          data['routes'].isNotEmpty &&
          data['routes'][0]['legs'] != null &&
          data['routes'][0]['legs'][0]['points'] != null) {
        
        final routePoints = <LatLng>[];

        // Assuming TomTom response contains route geometry in a specific format.
        final geometry = data['routes'][0]['legs'][0]['points'];

        for (var point in geometry) {
          final lat = point['lat'] ?? 0.0; // Default to 0.0 if null
          final lon = point['lon'] ?? 0.0; // Default to 0.0 if null

          // Ensure lat and lon are valid numbers
          if (lat != null && lon != null) {
            routePoints.add(LatLng(lat, lon));
          }
        }

        return routePoints;
      } else {
        throw Exception('No valid route data found in the TomTom response');
      }
    } else {
      throw Exception('Failed to load route from TomTom. Status code: ${response.statusCode}');
    }
  }
}
