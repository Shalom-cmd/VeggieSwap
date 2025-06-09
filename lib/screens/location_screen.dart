import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};  // Store the markers that the user pins
  LatLng? _userLocation; // Store the user's current location
  TextEditingController _descriptionController = TextEditingController();  // Controller for description input

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      final position = await _getCurrentLocation();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: MarkerId('user_location'),
            position: _userLocation!,
            infoWindow: InfoWindow(
              title: 'Your Location',
            ),
          ),
        );
      });

      if (_mapController != null && _userLocation != null) {
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          _userLocation!,
          12.0, // Zoom level adjusted for the user's area
        ));
      }
    } catch (error) {
      print("Error initializing map: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch location. Showing default view.")),
      );

      // Fallback to Chico location if fetching the user's location fails
      setState(() {
        _userLocation = LatLng(39.7285, -121.8375); // Default location for Chico, CA
        _markers.add(
          Marker(
            markerId: MarkerId('user_location'),
            position: _userLocation!,
            infoWindow: InfoWindow(
              title: 'Chico, CA',
            ),
          ),
        );
      });

      if (_mapController != null && _userLocation != null) {
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          _userLocation!,
          12.0,
        ));
      }
    }
  }

  // Function to get the current location of the user
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        throw 'Location permission denied';
      }
    }

    // This method fetches location for the web
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Function to add a new marker when the user taps on the map
  void _addMarker(LatLng location) async {
    // Show dialog to enter description
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Description"),
          content: SingleChildScrollView(
            child: TextField(
              controller: _descriptionController,
              decoration: InputDecoration(hintText: 'Enter a description'),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // Check if description is empty
                if (_descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Description cannot be empty!')),
                  );
                  return;
                }

                // Ensure the user is authenticated
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You must be logged in to add a pin.')),
                  );
                  return;
                }

                // Save the pin's data to Firebase Firestore
                await FirebaseFirestore.instance
                    .collection('pinnedLocations')
                    .doc(user.uid) // Store in user-specific collection
                    .collection('pins')
                    .add({
                  'location': GeoPoint(location.latitude, location.longitude),
                  'description': _descriptionController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // Add the marker to the map
                setState(() {
                  _markers.add(
                    Marker(
                      markerId: MarkerId(location.toString()), // Ensure unique ID
                      position: location,
                      infoWindow: InfoWindow(
                        title: "Pinned Location",  // Fixed title
                        snippet: _descriptionController.text,  // Description as snippet
                      ),
                    ),
                  );
                  _descriptionController.clear(); // Clear description field after adding
                });

                // Close the dialog
                Navigator.of(context).pop();
              },
              child: Text('Add Pin'),
            ),
            TextButton(
              onPressed: () {
                // Clear the description text field and close the dialog
                _descriptionController.clear();
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Pin Your Favorite Places"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Add a location and give it a description, it could be a vegan restaurant, a farmers market, or a vegan store. Include items/food bought.",
                style: TextStyle(fontSize: 16),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pinnedLocations')
                    .doc(FirebaseAuth.instance.currentUser?.uid ?? '') // Use the user's UID
                    .collection('pins')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.hasData) {
                    // Clear previous markers before updating the list
                    _markers.clear();

                    // Add new markers from Firestore data
                    for (var pin in snapshot.data!.docs) {
                      final location = pin['location'];
                      final description = pin['description'];

                      _markers.add(
                        Marker(
                          markerId: MarkerId(pin.id),
                          position: LatLng(location.latitude, location.longitude),
                          infoWindow: InfoWindow(
                            title: "Pinned Location",
                            snippet: description,
                          ),
                        ),
                      );
                    }
                  }

                  return GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(39.7285, -121.8375), // Default to Chico, CA
                      zoom: 12.0, // Adjust zoom to a more localized level
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onTap: (LatLng tappedPoint) {
                      print("Map tapped at: $tappedPoint");
                      _addMarker(tappedPoint);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  @override
  void dispose() {
    _mapController?.dispose();  // Dispose of the map controller when done
    super.dispose();
  }
}