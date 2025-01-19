import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class RestaurantScreen extends StatefulWidget {
  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  late GoogleMapController mapController;
  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    initLocation();
  }

  initLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    if (_locationData != null) {
      setState(() {
        _markers.add(Marker(
          markerId: MarkerId('currentLocation'),
          position: LatLng(_locationData!.latitude ?? 0, _locationData!.longitude ?? 0),
          infoWindow: InfoWindow(title: 'You are here'),
        ));

        mapController.moveCamera(
          CameraUpdate.newLatLng(LatLng(_locationData!.latitude ?? 0, _locationData!.longitude ?? 0)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Restaurants'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(37.7749, -122.4194), // Default location (San Francisco)
          zoom: 14.0,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: _markers,
      ),
    );
  }
}
