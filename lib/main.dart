// Created 14.03.2024 by Christopher Schilling
// Last Modified 24.02.2025
//
// The file builds the visuals of the charging station app. It also implements
// some helper functions
//
// __version__ = "1.1.1"
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
  late MapController mapController;
  TextEditingController searchController = TextEditingController();
  Position? currentPosition;
  List<ChargingStationInfo> chargingStations = [];

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _initialize();
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

    setState(() {
      mapController.move(initialPosition, 12.0);
      currentPosition = position;
    });

    final apiService = ApiService();
    try {
      final stations = await apiService.fetchChargingStations();
      setState(() {
        chargingStations = stations;
      });
    } catch (e) {
      // Handle API fetch failure
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      // Show manual charging station for presenting (fallback)
      setState(() {
        chargingStations = []; // Clear existing stations

        // Beispielhafte EVSE-Daten
        Map<String, EvseInfo> evsesMap = {
          'evse_1': EvseInfo(
            evseNumber: 'evse_1',
            maxPower: 22, // kW
            status: 'AVAILABLE',
            illegallyParked: false,
          ),
          'evse_2': EvseInfo(
            evseNumber: 'evse_2',
            maxPower: 50, // Schnelllader
            status: 'CHARGING',
            illegallyParked: false,
          ),
          'evse_3': EvseInfo(
            evseNumber: 'evse_3',
            maxPower: 11, // Langsamerer Lader
            status: 'AVAILABLE',
            illegallyParked: true, // Blockiert
          ),
        };

        // Manuelle Ladesäule hinzufügen
        chargingStations.add(ChargingStationInfo(
          id: 'manual_1',
          address: 'Test Ladesäule',
          city: 'Potsdam',
          coordinates: const LatLng(52.4, 13.1),
          freechargers: evsesMap.values
              .where((evse) => evse.status == 'AVAILABLE')
              .length,
          evses: evsesMap,
        ));
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
            AbsorbPointer(
              absorbing: isOverlayVisible,
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
            if (selectedStation != null) _buildStationDetails(),
            if (isOverlayVisible) _buildSearchOverlay(),
            if (!isOverlayVisible) _buildSearchButton(),
          ],
        ),
        bottomNavigationBar: (selectedStation == null && !isOverlayVisible)
            ? _buildBottomBar()
            : null, // Bottom bar is hidden when the station details or overlay are visible
      ),
    );
  }

  /// Builds the station details view
  Widget _buildStationDetails() {
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
                                      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(selectedStation!.address)}'));
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  if (currentPosition != null)
                    Text(
                      formatDistance(calculateDistance(
                          currentPosition!, selectedStation!.coordinates)),
                      style: const TextStyle(fontSize: 20.0),
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
                                              ? 'Frei'
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
            // Button für "Gespeichert"
            ElevatedButton(
              onPressed: () {
                // Aktion für "Gespeichert"-Button
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
                // Aktion für "Einstellungen"-Button
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
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Aktion für "Einstellungen"-Button
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Hilfe',
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
}
