import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// calculate the distance between the current location and the charging station
double calculateDistance(Position currentPosition, LatLng stationPosition) {
  double distanceInMeters = Geolocator.distanceBetween(
    currentPosition.latitude,
    currentPosition.longitude,
    stationPosition.latitude,
    stationPosition.longitude,
  );
  return distanceInMeters / 1000;
}

/// Formatting the distance of the user to the charging station. (meter: if distance > 1km)
String formatDistance(double distance) {
  if (distance < 1) {
    return '${(distance * 1000).toStringAsFixed(0)} m';
  } else {
    return '${distance.toStringAsFixed(2)} km';
  }
}
