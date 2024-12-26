import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import '../services/trajet_service.dart'; // Adjust the path as needed
import '../models/trajet.dart'; // Adjust the path as needed

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/login'));
              },
            ),
          ],
        ),
      ),
      body: const MapWidget(),
    );
  }
}

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late Future<List<Trajet>> trajets;
  Location location = Location();
  LocationData? _currentLocation;
  late MapController _mapController;
  bool _isLocationInitialized = false;
  List<Polyline> polylines = [];

  @override
  void initState() {
    super.initState();
    trajets = TrajetService.fetchTrajets();
    _mapController = MapController();
    _initializeLocation();
  }

  // Initialize the location service
  Future<void> _initializeLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get the current location data
    _currentLocation = await location.getLocation();
    setState(() {
      _isLocationInitialized = true;
    });
    _moveCameraToCurrentLocation();
  }

  // Move camera to the current location
  Future<void> _moveCameraToCurrentLocation() async {
    if (_isLocationInitialized && _currentLocation != null) {
      _mapController.move(
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        14.0,
      );
    }
  }

  // Function to get the route and distance between two points using OpenRouteService
  Future<Map<String, dynamic>> getRoute(LatLng start, LatLng end) async {
    final apiKey = '5b3ce3597851110001cf6248a46fc7595ee94509880b177cdbbea008'; // Replace with your OpenRouteService API key
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['features'][0]['geometry']['coordinates'] as List;
      final distance = data['features'][0]['properties']['segments'][0]['distance'];
      return {'route': route, 'distance': distance};
    } else {
      throw Exception('Failed to load route');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Trajet>>(
      future: trajets,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No trajets found.'));
        } else {
          final markers = <Marker>[];

          for (final trajet in snapshot.data!) {
            final departPoint = LatLng(
              trajet.pointDepart?['latitude'] ?? 0.0,
              trajet.pointDepart?['longitude'] ?? 0.0,
            );
            final arriveePoint = LatLng(
              trajet.pointArrivee?['latitude'] ?? 0.0,
              trajet.pointArrivee?['longitude'] ?? 0.0,
            );

            markers.addAll([
              Marker(
                width: 80,
                height: 80,
                point: departPoint,
                builder: (ctx) =>
                    const Icon(Icons.location_on, color: Colors.red),
              ),
              Marker(
                width: 80,
                height: 80,
                point: arriveePoint,
                builder: (ctx) =>
                    const Icon(Icons.location_on, color: Colors.green),
              ),
            ]);

            // Get the route and distance and update the map
            getRoute(departPoint, arriveePoint).then((routeData) {
              final route = routeData['route'] as List;
              final distance = routeData['distance'];
              print('Distance: $distance meters');

              // Add the polyline for the route
              setState(() {
                final polyline = Polyline(
                  points: route.map((coord) => LatLng(coord[1], coord[0])).toList(),
                  color: Colors.blue,
                  strokeWidth: 4.0,
                );
                polylines.add(polyline); // Add the polyline to the list
              });
            });
          }

          return FlutterMap(
            options: MapOptions(
              center: _isLocationInitialized && _currentLocation != null
                  ? LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)
                  : LatLng(31.6295, -7.9811), // Default location if not initialized
              zoom: 12.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              interactiveFlags: InteractiveFlag.all,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                additionalOptions: {
                  'attribution': '© OpenStreetMap contributors',
                },
              ),
              MarkerLayer(markers: markers),
              PolylineLayer(polylines: polylines), // Add polylines to the layer
            ],
            mapController: _mapController,
          );
        }
      },
    );
  }
}
