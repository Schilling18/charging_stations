// Created 14.03.2024 by Christopher Schilling
//
// The file stores logicfunctions, which are used across the project.
//
// __version__ = "1.0.1"
//
// __author__ = "Christopher Schilling"
//

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';

const String _selectedSpeedKey = 'selected_speed';
const String _selectedPlugsKey = 'selected_plugs';

/// Berechnet die Entfernung zwischen der aktuellen Position und einer Ladestation
double calculateDistance(Position currentPosition, LatLng stationPosition) {
  double distanceInMeters = Geolocator.distanceBetween(
    currentPosition.latitude,
    currentPosition.longitude,
    stationPosition.latitude,
    stationPosition.longitude,
  );
  return distanceInMeters / 1000;
}

/// Formatiert die Entfernung zur Ladestation (m, wenn < 1 km, sonst km)
String formatDistance(double distance) {
  if (distance < 1) {
    return '${(distance * 1000).toStringAsFixed(0)} m';
  } else {
    return '${distance.toStringAsFixed(2)} km';
  }
}

/// Zeigt einen Dialog an, wenn die Standortberechtigung verweigert wurde
void showPermissionDeniedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Standortberechtigung verweigert"),
        content: const Text(
            "Um nahegelegene Ladestationen korrekt anzuzeigen, ist ein Standortzugriff erforderlich. Dies kann in den Einstellungen geändert werden."),
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

/// Bewegt die Karte auf die aktuelle Position
void moveToLocation(
    MapController mapController, bool selectedFromList, LatLng point) {
  const zoomLevel = 15.0;
  if (selectedFromList) {
    mapController.move(point, zoomLevel);
  }
}

/// Überprüft und fordert die Standortberechtigung an
Future<int> checkLocationPermission() async {
  var status = await Permission.locationWhenInUse.status;
  if (status.isDenied) {
    status = await Permission.locationWhenInUse.request();
  }
  if (status.isGranted) {
    return 1; // Berechtigung gewährt
  } else {
    return 0; // Berechtigung verweigert
  }
}

const String _favoritesKey = 'favorites';

/// Lädt gespeicherte Favoriten aus SharedPreferences
Future<Set<String>> loadFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_favoritesKey)?.toSet() ?? {};
}

/// Speichert die übergebenen Favoriten dauerhaft in SharedPreferences
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

/// Speichert die ausgewählte Ladegeschwindigkeit
Future<void> saveSelectedSpeed(String speed) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_selectedSpeedKey, speed);
}

/// Speichert die ausgewählten Stecker
Future<void> saveSelectedPlugs(Set<String> plugs) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_selectedPlugsKey, plugs.toList());
}

/// Lädt die gespeicherte Ladegeschwindigkeit
Future<String> loadSelectedSpeed() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_selectedSpeedKey) ?? 'Alle';
}

/// Lädt die gespeicherten Stecker
Future<Set<String>> loadSelectedPlugs() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_selectedPlugsKey)?.toSet() ?? {};
}
