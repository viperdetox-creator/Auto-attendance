import 'package:geolocator/geolocator.dart';

class GeofenceService {
  final double centerLat;
  final double centerLng;
  final double radiusInMeters;

  bool _isInside = false;

  GeofenceService({
    required this.centerLat,
    required this.centerLng,
    this.radiusInMeters = 50,
  });

  /// Returns true only when inside/outside state changes
  bool check(Position position) {
    final distance = Geolocator.distanceBetween(
      centerLat,
      centerLng,
      position.latitude,
      position.longitude,
    );

    final inside = distance <= radiusInMeters;

    if (inside != _isInside) {
      _isInside = inside;
      return true;
    }
    return false;
  }

  bool get isInside => _isInside;
}
