import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import '../../../../core/constants/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  MapController _mapController = MapController();
  LatLng _pickedLocation = LatLng(19.0760, 72.8777); // Default: Mumbai
  String? _address;
  bool _loading = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  Future<void> _setInitialLocation() async {
    setState(() {
      _locating = true;
    });
    try {
      loc.Location location = loc.Location();
      bool _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) return;
      }
      loc.PermissionStatus _permissionGranted = await location.hasPermission();
      if (_permissionGranted == loc.PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != loc.PermissionStatus.granted) return;
      }
      final userLoc = await location.getLocation();
      final userLatLng =
          LatLng(userLoc.latitude ?? 19.0760, userLoc.longitude ?? 72.8777);
      setState(() {
        _pickedLocation = userLatLng;
        _locating = false;
      });
      _mapController.move(userLatLng, 14);
    } catch (e) {
      setState(() {
        _locating = false;
      });
    }
  }

  void _onMapTap(LatLng position) async {
    setState(() {
      _pickedLocation = position;
      _loading = true;
      _address = null;
    });
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = [
            place.name,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          _loading = false;
        });
      } else {
        setState(() {
          _address = 'No address found';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Error fetching address';
        _loading = false;
      });
    }
  }

  void _onConfirm() {
    Navigator.pop(context, {
      'lat': _pickedLocation.latitude,
      'lng': _pickedLocation.longitude,
      'address': _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _pickedLocation,
              zoom: 16,
              onTap: (tapPosition, latlng) {
                _onMapTap(latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.onetap365app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 48.0,
                    height: 48.0,
                    point: _pickedLocation,
                    child: Icon(Icons.location_on,
                        color: AppColors.primary, size: 48),
                  ),
                ],
              ),
            ],
          ),

          // Search bar (rounded, dark, with search icon)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.search, color: Colors.white70),
                        ),
                        const Expanded(
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search an area or address',
                              hintStyle: TextStyle(color: Colors.white54),
                              isDense: true,
                            ),
                            enabled: false, // UI only
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Current location button
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                icon: Icon(Icons.my_location, color: AppColors.primary),
                label: Text('Current location',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
                onPressed: _setInitialLocation,
              ),
            ),
          ),

          // Bottom sheet with address and confirm
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.my_location,
                            color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text('Current location',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Order will be delivered here',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _address ?? 'Tap on map to pick location',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _address != null ? _onConfirm : null,
                      child: const Text('Confirm & proceed',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_loading || _locating)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
