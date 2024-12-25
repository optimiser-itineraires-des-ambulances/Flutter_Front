import 'package:latlong2/latlong.dart';

class Trajet {
  final String id;
  final Map<String, double> pointDepart;
  final Map<String, double> pointArrivee;
  final int hopitalId;
  List<LatLng>? route; // Added route property

  Trajet({
    required this.id,
    required this.pointDepart,
    required this.pointArrivee,
    required this.hopitalId,
    this.route, // Optional parameter for route
  });

  factory Trajet.fromJson(Map<String, dynamic> json) {
    return Trajet(
      id: json['id'],
      pointDepart: Map<String, double>.from(json['pointDepart']),
      pointArrivee: Map<String, double>.from(json['pointArrivee']),
      hopitalId: json['hopital_id'],
    );
  }
}
