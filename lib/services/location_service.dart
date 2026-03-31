import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        type: LocationErrorType.serviceDisabled,
        message:
            'Location services are turned off on your device. Please enable them in Settings.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw LocationException(
          type: LocationErrorType.permissionDenied,
          message:
              'Location permission was denied. Please allow access to get your UV index.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        type: LocationErrorType.permissionPermanentlyDenied,
        message:
            'Location permission is permanently denied. Please enable it in your device Settings.',
      );
    }

    // First, try to get the very last known position. 
    // We only use it if it's extremely fresh (under 1 minute).
    final lastKnown = await Geolocator.getLastKnownPosition(
      forceAndroidLocationManager: true,
    );
    if (lastKnown != null) {
      final age = DateTime.now().difference(lastKnown.timestamp);
      if (age.inMinutes < 1) {
        print('[UV INDEX] Using fresh cached position (age: ${age.inSeconds}s)');
        return lastKnown;
      }
    }

    try {
      print('[UV INDEX] Fetching LIVE GPS position (high accuracy)...');
      // forceAndroidLocationManager bypasses the Google Play Services fused
      // location provider which can hang indefinitely on some Android devices.
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 12),
      );
    } on TimeoutException {
      // On timeout, accept any cached position regardless of age as a fallback
      if (lastKnown != null) {
        print('[UV INDEX] Live GPS timed out, falling back to last known position');
        return lastKnown;
      }

      throw const LocationException(
        type: LocationErrorType.locationUnavailable,
        message:
            'We could not get your current location in time. Please make sure GPS is on and try again.',
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        type: LocationErrorType.serviceDisabled,
        message:
            'Location services are turned off on your device. Please enable them in Settings.',
      );
    } catch (e) {
      if (lastKnown != null) {
        print('[UV INDEX] Live GPS failed ($e), falling back to last known position');
        return lastKnown;
      }

      throw const LocationException(
        type: LocationErrorType.locationUnavailable,
        message:
            'We could not get your current location right now. Please try again in a moment.',
      );
    }
  }
}

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  locationUnavailable,
}

class LocationException implements Exception {
  final LocationErrorType type;
  final String message;

  const LocationException({required this.type, required this.message});

  @override
  String toString() => message;
}
