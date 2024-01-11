import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dataBasdHandles.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  List<Marker> markers = [];
  final dbHelper = DatabaseHelper.instance;
  LatLng centerLatLng = LatLng(37.7749, -122.4194); // Default center

  @override
  void initState() {
    super.initState();
    _loadMarkersFromDatabase();
  }

  void _loadMarkersFromDatabase() async {
    final markersData = await dbHelper.getMarkers();
    setState(() {
      markers = markersData
          .map(
            (markerData) => Marker(
          markerId: MarkerId(markerData['lat'].toString() +
              '_' +
              markerData['lng'].toString()),
          position: LatLng(markerData['lat'], markerData['lng']),
          infoWindow: InfoWindow(
            onTap: () => _onMarkerTap(LatLng(markerData['lat'], markerData['lng'])),
            title: 'Marker ${markerData['lat']}, ${markerData['lng']}',
            snippet: 'Tap to remove',
          ),
        ),
      )
          .toList();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _onMapTap(LatLng position) async {
    // Add marker to the map
    final marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(
        onTap: () => _onMarkerTap(position),
        title: 'Marker ${position.latitude}, ${position.longitude}',
        snippet: 'Tap to remove',
      ),

    );

    setState(() {
      markers.add(marker);
    });

    // Save marker details to local database
    _saveMarkerToDatabase(position);
  }

  void _onMarkerTap(LatLng position) async {
    // Remove marker from the map
    setState(() {
      markers.removeWhere((marker) => marker.position == position);
    });

    // Remove marker details from local database
    _removeMarkerFromDatabase(position);
  }

  Future<void> _saveMarkerToDatabase(LatLng position) async {
    final lat = position.latitude;
    final lng = position.longitude;

    await dbHelper.insertMarker(lat, lng);
  }

  Future<void> _removeMarkerFromDatabase(LatLng position) async {
    final lat = position.latitude;
    final lng = position.longitude;

    await dbHelper.deleteMarker(lat, lng);
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      centerLatLng = position.target;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Chordify'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onTap: _onMapTap,
            markers: Set.from(markers),
            initialCameraPosition: CameraPosition(
              target: centerLatLng,
              zoom: 14.0,
            ),
            onCameraMove: _onCameraMove,
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue, width: 2.0),
              ),
              child: Text(
                'Center Lat: ${centerLatLng.latitude.toStringAsFixed(6)}\nCenter Lng: ${centerLatLng.longitude.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
