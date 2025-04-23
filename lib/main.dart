// Created 14.03.2024 by Christopher Schilling
// Last Modified 23.04.2025
//
// The file builds the visuals of the charging station app.
//
// __version__ = "1.2.5"
//
// __author__ = "Christopher Schilling"
//

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'functions.dart';

/// Main
void main() {
  runApp(const ChargingStationApp());
}

/// Main application widget
class ChargingStationApp extends StatelessWidget {
  const ChargingStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChargingStation(),
    );
  }
}

/// Stateful widget for the Charging Station screen
class ChargingStation extends StatefulWidget {
  const ChargingStation({super.key});

  @override
  ChargingStationState createState() => ChargingStationState();
}

class ChargingStationState extends State<ChargingStation> {
  ChargingStationState();
  ChargingStationInfo? selectedStation;

  bool isOverlayVisible = false;
  bool selectedFromList = false;
  bool showFavoritesOverlay = false;
  bool showSettingsOverlay = false;
  bool showFilterOverlay = false;

  late MapController mapController;
  TextEditingController searchController = TextEditingController();
  Position? currentPosition;
  List<ChargingStationInfo> chargingStations = [];
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _loadFavorites();
    _initialize();
  }

  Future<void> _loadFavorites() async {
    _favorites = await loadFavorites();
    setState(() {
      _favorites = _favorites;
    });
  }

  /// An async method to handle initialization logic
  Future<void> _initialize() async {
    LatLng initialPosition = const LatLng(52.390568, 13.064472);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    Position? position;

    if (serviceEnabled) {
      try {
        position = await Geolocator.getCurrentPosition();
        initialPosition = LatLng(position.latitude, position.longitude);
      } catch (e) {
        initialPosition = const LatLng(52.390568, 13.064472);
      }
    }

    if (!mounted) return; // ← prüft ob Widget noch aktiv ist

    setState(() {
      mapController.move(initialPosition, 12.0);
      currentPosition = position;
    });

    final apiService = ApiService();
    try {
      final stations = await apiService.fetchChargingStations();
      if (!mounted) return;

      setState(() {
        chargingStations = stations;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      if (!mounted) return;
      setState(() {
        chargingStations = [];
      });
    }
  }

  void _moveToLocation(LatLng point) {
    moveToLocation(mapController, selectedFromList, point);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
      child: Scaffold(
        body: Stack(
          children: [
            // Karte
            AbsorbPointer(
              absorbing: isOverlayVisible ||
                  showFavoritesOverlay ||
                  showSettingsOverlay ||
                  showFilterOverlay,
              child: FlutterMap(
                mapController: mapController,
                options: const MapOptions(
                  initialCenter: LatLng(52.390568, 13.064472),
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: chargingStations
                        .where((station) => station.city == 'Potsdam')
                        .map((station) {
                      bool isAvailable = station.evses.values
                          .any((evse) => evse.status == 'AVAILABLE');
                      Color iconColor =
                          isAvailable ? Colors.green : Colors.grey;
                      return Marker(
                        width: 40.0,
                        height: 40.0,
                        point: station.coordinates,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedStation = station;
                              selectedFromList = false;
                            });
                          },
                          child: Icon(
                            Icons.location_on,
                            size: 40.0,
                            color: iconColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Station Details
            if (selectedStation != null) _buildStationDetails(),

            // Such-Overlay
            if (isOverlayVisible) _buildSearchOverlay(),

            // Favoriten-Overlay
            if (showFavoritesOverlay) _buildFavoritesOverlay(),

            // Einstellungen-Overlay
            if (showSettingsOverlay) _buildSettingsOverlay(),

            // Filter-Overlay
            if (showFilterOverlay) _buildFilterOverlay(),

            // Such-Button (nur sichtbar wenn kein Overlay aktiv ist)
            if (!isOverlayVisible &&
                !showFavoritesOverlay &&
                !showSettingsOverlay &&
                !showFilterOverlay)
              _buildSearchButton(),

            // Reload-Button (nur sichtbar wenn kein Overlay aktiv ist)
            if (!isOverlayVisible &&
                !showFavoritesOverlay &&
                !showSettingsOverlay &&
                !showFilterOverlay)
              _buildReloadButton(),
          ],
        ),

        // Bottom Bar (nur wenn keine Details und keine Overlays aktiv)
        bottomNavigationBar: (selectedStation == null &&
                !isOverlayVisible &&
                !showFavoritesOverlay &&
                !showSettingsOverlay &&
                !showFilterOverlay)
            ? _buildBottomBar()
            : null,
      ),
    );
  }

  /// Builds the station details view
  Widget _buildStationDetails() {
    final stationId = selectedStation!.id.toString();
    final isFav = isFavorite(_favorites, stationId);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < 0) {
            setState(() {
              selectedStation = null;
              selectedFromList = false;
            });
          }
        },
        child: Dismissible(
          key: const ValueKey("dismissible"),
          direction: DismissDirection.down,
          onDismissed: (direction) {
            setState(() {
              selectedStation = null;
              selectedFromList = false;
            });
          },
          child: Container(
            height: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0),
              ),
              border: Border.all(
                color: Colors.grey,
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          selectedStation!.address,
                          style: const TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10.0),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  launchUrl(Uri.parse(
                                    'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(selectedStation!.address)}',
                                  ));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                ),
                                child: const Text(
                                  'Route',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              _buildAvailabilityButton(selectedStation!),
                              const SizedBox(width: 10.0),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    // Den Favoriten-Status ändern und die Liste aktualisieren
                                    if (isFav) {
                                      // Entfernen
                                      _favorites.remove(stationId);
                                    } else {
                                      // Hinzufügen
                                      _favorites.add(stationId);
                                    }
                                  });
                                  saveFavorites(_favorites);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isFav ? Colors.green : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                ),
                                child: Text(
                                  isFav ? 'Favorit' : 'Favorisieren',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  if (currentPosition != null)
                    Center(
                      child: Text(
                        'Entfernung: ${formatDistance(calculateDistance(currentPosition!, selectedStation!.coordinates))}',
                        style: const TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10.0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var evse
                              in selectedStation!.evses.values.toList()
                                ..sort((a, b) => a.status.compareTo(b.status)))
                            Column(
                              children: [
                                const Divider(
                                  color: Colors.grey,
                                  thickness: 1.0,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: evse.status == 'AVAILABLE'
                                              ? Colors.green
                                              : Colors.red,
                                          size: 24.0,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          evse.status == 'AVAILABLE'
                                              ? 'Verfügbar'
                                              : 'Besetzt',
                                          style: const TextStyle(
                                            fontSize: 20.0,
                                          ),
                                        ),
                                        Text(
                                          '${evse.maxPower} kW',
                                          style: const TextStyle(
                                            fontSize: 20.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the availability button on the Dismissible Widget
  Widget _buildAvailabilityButton(ChargingStationInfo station) {
    int availableCount =
        station.evses.values.where((evse) => evse.status == 'AVAILABLE').length;
    bool isAvailable = availableCount > 0;
    return ElevatedButton(
      onPressed: () {
        //Not a Button, chose widget for style reasons
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isAvailable ? Colors.green : Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
      ),
      child: Text(
        '$availableCount Verfügbar',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the search overlay
  Widget _buildSearchOverlay() {
    List<ChargingStationInfo> filteredStations = chargingStations
        .where((station) => station.city.toLowerCase() == 'potsdam')
        .where((station) => station.address
            .toLowerCase()
            .contains(searchController.text.toLowerCase()))
        .toList();

    return Positioned.fill(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.grey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSearchContent(filteredStations),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  /// Fills the Search-view with content, containing various information
  Widget _buildSearchContent(List<ChargingStationInfo> filteredStations) {
    // Sort the charging stations by proximity
    if (currentPosition != null) {
      filteredStations.sort((a, b) =>
          calculateDistance(currentPosition!, a.coordinates)
              .compareTo(calculateDistance(currentPosition!, b.coordinates)));
    } else {
      filteredStations.sort((a, b) => a.address.compareTo(b.address));
    }

    return Container(
      height: 700.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                isOverlayVisible = false;
              });
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: const BorderSide(color: Colors.grey, width: 2.0),
                ),
              ),
            ),
            child: SizedBox(
              height: 60.0,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Ladesäule suchen',
                        contentPadding:
                            EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 15.0),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        isOverlayVisible = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: ListView.builder(
              itemCount: filteredStations.length,
              itemBuilder: (context, index) {
                ChargingStationInfo station = filteredStations[index];
                int availableCount = station.evses.values
                    .where((evse) => evse.status == 'AVAILABLE')
                    .length;

                String subtitleText = '';
                if (currentPosition != null) {
                  double distance =
                      calculateDistance(currentPosition!, station.coordinates);
                  subtitleText = '${formatDistance(distance)} entfernt, ';
                }

                if (availableCount == 1) {
                  subtitleText += '$availableCount Ladesäule frei';
                } else {
                  subtitleText += '$availableCount Ladesäulen frei';
                }

                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        station.address,
                        style: const TextStyle(
                          fontSize: 21.0,
                        ),
                      ),
                      subtitle: Text(
                        subtitleText,
                        style: const TextStyle(
                          fontSize: 18.0,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedStation = station;
                          isOverlayVisible = false;
                          selectedFromList = true;
                        });
                        _moveToLocation(station.coordinates);
                      },
                    ),
                    const SizedBox(height: 16.0),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the search button
  Widget _buildSearchButton() {
    return Positioned(
      top: 78,
      left: 16.0,
      right: 16.0,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            isOverlayVisible = true;
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: const BorderSide(color: Colors.grey, width: 2.0),
            ),
          ),
        ),
        child: const SizedBox(
          height: 55.0,
          child: Center(
            child: Text(
              'Ladesäule suchen',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the bottom navigation bar
  Widget _buildBottomBar() {
    return BottomAppBar(
      height: 70,
      color: Colors.grey[400],
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Button für "Favoriten"
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Nur Favoriten anzeigen, andere schließen
                  showFavoritesOverlay = !showFavoritesOverlay;
                  isOverlayVisible = false;
                  showSettingsOverlay = false;
                  showFilterOverlay = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Favoriten',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black,
                ),
              ),
            ),

            // Button für "Einstellungen"
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Nur Einstellungen anzeigen, andere schließen
                  isOverlayVisible = false;
                  showFavoritesOverlay = false;
                  showSettingsOverlay = true;
                  showFilterOverlay = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Einstellungen',
                style: TextStyle(fontSize: 16.0, color: Colors.black),
              ),
            ),

            // Button für "Filter"
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Nur Filter anzeigen, andere schließen
                  isOverlayVisible = false;
                  showFavoritesOverlay = false;
                  showSettingsOverlay = false;
                  showFilterOverlay = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Filter',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesOverlay() {
    final favoriteStations = chargingStations
        .where((station) => _favorites.contains(station.id))
        .toList();

    if (currentPosition != null) {
      favoriteStations.sort((a, b) =>
          calculateDistance(currentPosition!, a.coordinates)
              .compareTo(calculateDistance(currentPosition!, b.coordinates)));
    } else {
      favoriteStations.sort((a, b) => a.address.compareTo(b.address));
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.grey.withOpacity(1),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Überschrift + Favoriten-Schließen-Button in einer Zeile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Favoriten",
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                      onPressed: () {
                        setState(() {
                          showFavoritesOverlay = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
                // Favoritenliste
                Expanded(
                  child: favoriteStations.isEmpty
                      ? const Center(
                          child: Text(
                            "Keine Favoriten vorhanden.",
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                        )
                      : ListView.separated(
                          itemCount: favoriteStations.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white24),
                          itemBuilder: (context, index) {
                            final station = favoriteStations[index];
                            int availableCount = station.evses.values
                                .where((evse) => evse.status == 'AVAILABLE')
                                .length;

                            String subtitleText = '';
                            if (currentPosition != null) {
                              double distance = calculateDistance(
                                  currentPosition!, station.coordinates);
                              subtitleText =
                                  '${formatDistance(distance)} entfernt, ';
                            }

                            subtitleText += availableCount == 1
                                ? '1 Ladesäule frei'
                                : '$availableCount Ladesäulen frei';

                            return ListTile(
                              title: Text(
                                station.address,
                                style: const TextStyle(
                                  fontSize: 21.0,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                subtitleText,
                                style: const TextStyle(
                                  fontSize: 17.0,
                                  color: Colors.black,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedStation = station;
                                  showFavoritesOverlay = false;
                                  selectedFromList = true;
                                });
                                _moveToLocation(station.coordinates);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOverlay() {
    String selectedLanguage = 'Deutsch';
    String selectedTheme = 'Dunkel';

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.grey.withOpacity(1),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Überschrift + Schließen-Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Einstellungen",
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                      onPressed: () {
                        setState(() {
                          showSettingsOverlay = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),

                // Sprache
                const Text(
                  'Sprache',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedLanguage,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: ['Deutsch', 'Englisch', 'Französisch', 'Spanisch']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: const TextStyle(color: Colors.black)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedLanguage = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Design (Theme Mode)
                const Text(
                  'Design',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTheme,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: ['Hell', 'Dunkel'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: const TextStyle(color: Colors.black)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedTheme = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Impressum
                const Text(
                  'Rechtliches',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Impressum anzeigen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Impressum',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),

                const Spacer(),

                // Anwenden
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showSettingsOverlay = false;
                      // Sprache/Thema übernehmen
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Anwenden',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOverlay() {
    // Ladegeschwindigkeit Auswahl
    final List<String> speedOptions = [
      'Alle',
      'Ab 50kW',
      'Ab 150kW',
      'Ab 300kW'
    ];
    String selectedSpeed = 'Alle';

    // Stecker Auswahl
    final List<String> plugOptions = [
      'Typ2',
      'CCS',
      'CHAdeMO',
      'SchuKo',
      'Tesla',
      'Andere',
    ];
    Set<String> selectedPlugs = {};

    return StatefulBuilder(
      builder: (context, setOverlayState) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            color: Colors.grey.withOpacity(1),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Überschrift + Schließen-Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filter",
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 28),
                          onPressed: () {
                            setState(() {
                              showFilterOverlay = false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),

                    // Kategorie: Ladegeschwindigkeit
                    const Text(
                      'Ladegeschwindigkeit',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10.0,
                      children: speedOptions.map((option) {
                        final isSelected = selectedSpeed == option;
                        return ChoiceChip(
                          label: Text(option),
                          selected: isSelected,
                          selectedColor: Colors.green,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          onSelected: (_) {
                            setOverlayState(() {
                              selectedSpeed = option;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Kategorie: Stecker
                    const Text(
                      'Stecker',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10.0,
                      children: plugOptions.map((plug) {
                        final isSelected = selectedPlugs.contains(plug);
                        return FilterChip(
                          label: Text(plug),
                          selected: isSelected,
                          selectedColor: Colors.green,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          onSelected: (selected) {
                            setOverlayState(() {
                              if (selected) {
                                selectedPlugs.add(plug);
                              } else {
                                selectedPlugs.remove(plug);
                              }
                            });
                          },
                          // Auch hier wird das Standard-Häkchen angezeigt
                        );
                      }).toList(),
                    ),

                    const Spacer(),

                    // Button zum Anwenden der Filter
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showFilterOverlay = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Filter anwenden',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReloadButton() {
    return Positioned(
      bottom: 20.0, // näher an der Bottom Bar als vorher (vorher 80.0)
      right: 16.0,
      child: FloatingActionButton(
        heroTag: 'reloadButton',
        backgroundColor: Colors.white,
        onPressed: () {
          _initialize(); // API wird aufgerufen, um Ladesäulen neu zu laden
        },
        child: const Icon(
          Icons.refresh,
          color: Colors.black,
        ),
      ),
    );
  }
}

class ReloadButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReloadButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80, // über der BottomBar
      right: 20,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
