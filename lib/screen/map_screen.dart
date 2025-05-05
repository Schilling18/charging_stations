import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:charging_station/widgets/bottom_bar.dart';
import 'package:charging_station/widgets/search_overlay.dart';
import 'package:charging_station/widgets/favorites_overlay.dart';
import 'package:charging_station/widgets/station_details.dart';
import 'package:charging_station/widgets/filter_overlay.dart';
import 'package:charging_station/widgets/settings_overlay.dart';
import 'package:charging_station/models/api.dart';
import 'package:charging_station/utils/helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  bool isOverlayVisible = false;
  bool showFavoritesOverlay = false;
  bool selectedFromList = false;
  bool showFilterOverlay = false;
  bool showSettingsOverlay = false;

  Position? currentPosition;
  LatLng? selectedCoordinates;
  ChargingStationInfo? selectedStation;

  List<ChargingStationInfo> chargingStations = [];
  Set<String> favoriteIds = {};

  final LatLng defaultCoordinates = const LatLng(52.3906, 13.0645); // Potsdam

  @override
  void initState() {
    super.initState();
    selectedCoordinates = defaultCoordinates;
    _loadCurrentPosition();
    _loadChargingStationsAndFavorites();
  }

  Future<void> _loadCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPosition = position;
        selectedCoordinates = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Fehlerbehandlung
    }
  }

  Future<void> _loadChargingStationsAndFavorites() async {
    try {
      final stations = await ApiService().fetchChargingStations();
      final favs = await loadFavorites();
      setState(() {
        chargingStations = stations;
        favoriteIds = favs;
      });
    } catch (e) {
      setState(() {
        chargingStations = [];
        favoriteIds = {};
      });
    }
  }

  void _onStationSelected(ChargingStationInfo station) {
    setState(() {
      selectedCoordinates = station.coordinates;
      selectedStation = station;
      selectedFromList = true;
      showFavoritesOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoriteStations = chargingStations
        .where((station) => isFavorite(favoriteIds, station.id.toString()))
        .toList();

    return Scaffold(
      body: isOverlayVisible
          ? _buildSearchOverlay()
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: selectedCoordinates ?? defaultCoordinates,
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: chargingStations.map((station) {
                        final isAvailable = station.evses.values
                            .any((evse) => evse.status == 'AVAILABLE');

                        return Marker(
                          width: 40.0,
                          height: 40.0,
                          point: station.coordinates,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCoordinates = station.coordinates;
                                selectedStation = station;
                                selectedFromList = false;
                              });
                            },
                            child: Icon(
                              Icons.location_on,
                              size: 40.0,
                              color: isAvailable ? Colors.green : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isOverlayVisible = true;
                        showFavoritesOverlay = false;
                        selectedStation = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5.0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Nach Station suchen...',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showFavoritesOverlay)
                  _buildFavoritesOverlay(favoriteStations),
                if (showFilterOverlay)
                  FilterOverlay(
                    onClose: () {
                      setState(() {
                        showFilterOverlay = false;
                      });
                    },
                  ),
                if (showSettingsOverlay)
                  SettingsOverlay(
                    onClose: () {
                      setState(() {
                        showSettingsOverlay = false;
                      });
                    },
                  ),
                if (selectedStation != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta! < 0) {
                          setState(() {
                            selectedStation = null;
                            selectedFromList = false;
                          });
                        }
                      },
                      child: Dismissible(
                        key: Key(selectedStation!.id.toString()),
                        direction: DismissDirection.down,
                        onDismissed: (direction) {
                          setState(() {
                            selectedStation = null;
                            selectedFromList = false;
                          });
                        },
                        child: StationDetailsWidget(
                          selectedStation: selectedStation!,
                          currentPosition: currentPosition,
                          isFavorite: isFavorite(
                              favoriteIds, selectedStation!.id.toString()),
                          toggleFavorite: (stationId) async {
                            final updated =
                                await toggleFavorite(favoriteIds, stationId);
                            setState(() {
                              favoriteIds = updated;
                            });
                          },
                          onDismiss: () {
                            setState(() {
                              selectedStation = null;
                              selectedFromList = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: isOverlayVisible ||
              selectedStation != null ||
              showFilterOverlay ||
              showFavoritesOverlay ||
              showSettingsOverlay
          ? const SizedBox.shrink()
          : _buildBottomBar(),
    );
  }

  Widget _buildSearchOverlay() => SearchOverlay(
        searchController: TextEditingController(),
        currentPosition: currentPosition,
        onClose: () {
          setState(() {
            isOverlayVisible = false;
          });
        },
        chargingStations: chargingStations,
        onStationSelected: (station) {
          _onStationSelected(station);
          setState(() {
            isOverlayVisible = false;
          });
        },
      );

  Widget _buildFavoritesOverlay(List<ChargingStationInfo> favoriteStations) =>
      FavoritesOverlay(
        favoriteStations: favoriteStations,
        currentPosition: currentPosition,
        onStationSelected: _onStationSelected,
        onClose: () {
          setState(() {
            showFavoritesOverlay = false;
          });
        },
        chargingStations: chargingStations,
      );

  Widget _buildBottomBar() => BottomBar(
        onFavoritesTap: () {
          setState(() {
            showFavoritesOverlay = !showFavoritesOverlay;
          });
        },
        onSettingsTap: () {
          setState(() {
            showSettingsOverlay = !showSettingsOverlay;
          });
        },
        onFilterTap: () {
          setState(() {
            showFilterOverlay = !showFilterOverlay;
          });
        },
      );
}
