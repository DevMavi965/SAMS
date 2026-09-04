import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GeofenceService {
  // Checks if current user location is within the allowed radius of the target coordinates
 static  validateGeofence({
   required BuildContext context,
    required double targetLatitude,
    required double targetLongitude,
    double allowedRadiusMeters = 50.0,
  }) async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location services are disabled. Please turn on GPS")));
       return false;
      }

      // 2. Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location permissions are denied.")));
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location permissions are permanently denied, enable them in settings.")));
       return false;
      }

      // 3 Fetchiing high-accuracy current position
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4 Calculate distance in meters using Haversine formula built into Geolocator
      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLatitude,
        targetLongitude,
      );
      print(currentPosition.toString());
      if (distanceInMeters <= allowedRadiusMeters) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Within boundary. You are ${distanceInMeters.toStringAsFixed(1)}m away (Max allowed: ${allowedRadiusMeters}m)'),backgroundColor: Theme.of(context).primaryColor,));
        return true;
      } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Out of bounds. You are ${distanceInMeters.toStringAsFixed(1)}m away (Max allowed: ${allowedRadiusMeters}m')));
      return false;
      }

    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      return false;
    }
  }
}