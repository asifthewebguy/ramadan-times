import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class LocationResult {
  final double lat;
  final double lng;
  final String city;

  const LocationResult({
    required this.lat,
    required this.lng,
    required this.city,
  });
}

enum LocationError { denied, deniedForever, serviceDisabled, unknown }

class LocationService {
  /// Request location permission and get current GPS position.
  /// Falls back to cached coordinates from SharedPreferences.
  /// Returns [LocationResult] or throws [LocationError].
  Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final cached = await _loadCached();
      if (cached != null) return cached;
      throw LocationError.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        final cached = await _loadCached();
        if (cached != null) return cached;
        throw LocationError.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      final cached = await _loadCached();
      if (cached != null) return cached;
      throw LocationError.deniedForever;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    final city = await _getCityName(position.latitude, position.longitude);
    final result = LocationResult(
      lat: position.latitude,
      lng: position.longitude,
      city: city,
    );
    await _cacheLocation(result);
    return result;
  }

  /// Reverse geocode [lat]/[lng] to a city name.
  Future<String> _getCityName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return p.locality?.isNotEmpty == true
            ? p.locality!
            : p.administrativeArea ?? 'Unknown';
      }
    } catch (_) {}
    return 'Unknown';
  }

  /// Search for a city by name and return matching [LocationResult]s.
  Future<List<LocationResult>> searchCity(String query) async {
    try {
      final locations = await locationFromAddress(query);
      final results = <LocationResult>[];
      for (final loc in locations.take(5)) {
        final city = await _getCityName(loc.latitude, loc.longitude);
        results.add(LocationResult(
          lat: loc.latitude,
          lng: loc.longitude,
          city: city.isEmpty ? query : city,
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheLocation(LocationResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyLat, result.lat);
    await prefs.setDouble(AppConstants.keyLng, result.lng);
    await prefs.setString(AppConstants.keyCity, result.city);
  }

  Future<LocationResult?> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(AppConstants.keyLat);
    final lng = prefs.getDouble(AppConstants.keyLng);
    final city = prefs.getString(AppConstants.keyCity);
    if (lat != null && lng != null) {
      return LocationResult(lat: lat, lng: lng, city: city ?? 'Unknown');
    }
    return null;
  }
}
