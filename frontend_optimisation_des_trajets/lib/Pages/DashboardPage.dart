import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
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
  late LocationData _currentLocation;
  late MapController _mapController;
  bool _isLocationInitialized = false; // Track if location is initialized

  @override
  void initState() {
    super.initState();
    trajets = TrajetService.fetchTrajets();
    _mapController = MapController();
    _initializeLocation();
  }

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

    _currentLocation = await location.getLocation();
    setState(() {
      _isLocationInitialized = true; // Location is initialized
    });

    // Move camera to the current location after it's initialized
    _moveCameraToCurrentLocation();
  }

  Future<void> _moveCameraToCurrentLocation() async {
    if (_isLocationInitialized && _mapController != null) {
      _mapController.move(
        LatLng(_currentLocation.latitude!, _currentLocation.longitude!),
        14.0, // Zoom level
      );
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
          // Create markers and polylines for routes
          final markers = <Marker>[];
          final polylines = <Polyline>[];

          for (final trajet in snapshot.data!) {
            // Add markers for depart and arrivee
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

            // Add polyline directly between depart and arrivee
            polylines.add(
              Polyline(
                points: [departPoint, arriveePoint],
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
            );
          }

          return FlutterMap(
            options: MapOptions(
              center: _isLocationInitialized
                  ? LatLng(_currentLocation.latitude!, _currentLocation.longitude!)
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
                userAgentPackageName: 'com.example.your_app',
                additionalOptions: {
                  'attribution': '© OpenStreetMap contributors',
                },
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      _currentLocation.latitude ?? 31.6295,
                      _currentLocation.longitude ?? -7.9811,
                    ),
                    width: 80,
                    height: 80,
                    builder: (ctx) => const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
            mapController: _mapController, // Directly use the initialized controller
          );
        }
      },
    );
  }
}
