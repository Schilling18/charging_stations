// Created 14.03.2024 by Christopher Schilling
// Last Modified 16.04.2024
//
// The file builds the visuals of the charging station app. It also implements
// some helper functions
//
// __version__ = "1.2.0"
//
// __author__ = "Christopher Schilling"
//

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Displays an error message if location permission is denied
void showPermissionDeniedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Standortberechtigung verweigert"),
        content: const Text(
            "Um nahegelegene Ladestationen korrekt anzuzeigen, ist ein Standortzugriff erforderlich. Dies kann in den Einstellungen verändet werden"),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

/// moves the map to the current location
void moveToLocation(
    MapController mapController, bool selectedFromList, LatLng point) {
  const zoomLevel = 15.0;
  if (selectedFromList) {
    mapController.move(point, zoomLevel);
  }
}

/// Checks and requests location permission
Future<int> checkLocationPermission() async {
  var status = await Permission.locationWhenInUse.status;
  if (status.isDenied) {
    status = await Permission.locationWhenInUse.request();
  }
  if (status.isGranted) {
    return 1;
  } else {
    return 0;
  }
}

/// -------------------------------
/// FAVORITEN-VERWALTUNG
/// -------------------------------

const String _favoritesKey = 'favorites';

/// Lädt gespeicherte Favoriten aus SharedPreferences
Future<Set<String>> loadFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_favoritesKey)?.toSet() ?? {};
}

/// Speichert die übergebenen Favoriten dauerhaft
Future<void> saveFavorites(Set<String> favorites) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_favoritesKey, favorites.toList());
}

/// Fügt eine ID zu den Favoriten hinzu oder entfernt sie
Future<Set<String>> toggleFavorite(
    Set<String> currentFavorites, String id) async {
  final updated = Set<String>.from(currentFavorites);
  if (updated.contains(id)) {
    updated.remove(id);
  } else {
    updated.add(id);
  }

  await saveFavorites(updated);
  return updated;
}

/// Prüft, ob eine ID ein Favorit ist
bool isFavorite(Set<String> favorites, String id) {
  return favorites.contains(id);
}
