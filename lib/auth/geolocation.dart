import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class Geolocation {
  // Function to check if the location permission is granted
  Future<bool> _checkLocationPermission() async {
    PermissionStatus permission = await Permission.location.request();
    return permission.isGranted;
  }

  // Function to get the current position of the user
  Future<Position?> getUserLocation() async {
    bool hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      // Updated to use locationSettings for accuracy
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high, // High accuracy
        distanceFilter: 10, // Minimum distance to move before updating
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      return position;
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  // Function to check if the user is in Malaysia (latitude and longitude boundaries)
  Future<bool> isUserInMalaysia() async {
    Position? position = await getUserLocation();
    if (position == null) {
      return false;
    }

    // Latitude and longitude boundaries of Malaysia
    double minLat = 1.0000;
    double maxLat = 7.5000;
    double minLng = 99.0000;
    double maxLng = 119.5000;

    // Check if the current position is within Malaysia's bounds
    bool isInMalaysia = position.latitude >= minLat &&
        position.latitude <= maxLat &&
        position.longitude >= minLng &&
        position.longitude <= maxLng;

    return isInMalaysia;
  }
}
