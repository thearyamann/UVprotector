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

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
}

class LocationException implements Exception {
  final LocationErrorType type;
  final String message;

  const LocationException({required this.type, required this.message});

  @override
  String toString() => message;
}
