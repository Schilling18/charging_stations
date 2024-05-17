import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'marker.dart';

void main() {
  runApp(const ChargingStationApp());
}

class ChargingStationApp extends StatelessWidget {
  const ChargingStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChargingStation(),
    );
  }
}

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
    _checkLocationPermission();
  }

  void _checkLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isGranted) {
      _initializeMapLocation();
    }
  }

  void _initializeMapLocation() async {
    LatLng initialPosition = const LatLng(52.390568, 13.064472);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        initialPosition = LatLng(position.latitude, position.longitude);
        currentPosition = position;
      } catch (e) {
        initialPosition = const LatLng(52.390568, 13.064472);
        currentPosition = null;
      }
    } else {
      initialPosition = const LatLng(52.390568, 13.064472);
      currentPosition = null;
    }
    setState(() {
      mapController.move(initialPosition, 12.0);
    });
    _fetchChargingStations();
  }

  void _fetchChargingStations() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://cs1-swp.westeurope.cloudapp.azure.com:8443/chargers'),
        headers: {'X-Api-Key': '6bcadbac-976e-4d6b-a593-f925fba25506'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        setState(() {
          chargingStations = data
              .map((station) => ChargingStationInfo.fromJson(station))
              .toList();
        });
      } else {
        _showErrorSnackbar('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching charging stations');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isOverlayVisible ? 0 : kToolbarHeight),
          child: AppBar(
            title: const Text('Ladesäulen'),
            backgroundColor: Colors.grey,
            centerTitle: true,
          ),
        ),
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
                        .map((station) => Marker(
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
                                child: const Icon(
                                  Icons.location_on,
                                  size: 40.0,
                                  color: Colors.red,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            if (selectedStation != null) _buildStationDetails(),
            if (isOverlayVisible) _buildSearchOverlay(),
            if (!isOverlayVisible) _buildSearchButton(),
          ],
        ),
      ),
    );
  }

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
                            fontSize: 20.0,
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
                                  // Define what the button does here
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
                              const SizedBox(
                                  width:
                                      10.0), // Add some spacing between the buttons
                              _buildAvailabilityButton(selectedStation!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Center(
                    child: Text(
                      '${_calculateDistance(currentPosition!, selectedStation!.coordinates).toStringAsFixed(2)} km',
                      style: const TextStyle(fontSize: 18.0),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var evse in selectedStation!.evses.values)
                            Column(
                              children: [
                                const Divider(
                                  color: Colors.grey,
                                  thickness: 1.0,
                                ),
                                Text(
                                  '${evse.maxPower} kw',
                                  style: const TextStyle(fontSize: 18.0),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Status: ${evse.status}',
                                  style: const TextStyle(fontSize: 18.0),
                                  textAlign: TextAlign.center,
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

  Widget _buildAvailabilityButton(ChargingStationInfo station) {
    int availableCount =
        station.evses.values.where((evse) => evse.status == 'AVAILABLE').length;
    bool isAvailable = availableCount > 0;
    return ElevatedButton(
      onPressed: () {
        // Define what the button does here
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

  Widget _buildSearchOverlay() {
    List<ChargingStationInfo> filteredStations = chargingStations
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

  Widget _buildSearchContent(List<ChargingStationInfo> filteredStations) {
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
                            EdgeInsets.fromLTRB(10.0, 16.0, 16.0, 19.0),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                return ListTile(
                  title: Text(station.address),
                  onTap: () {
                    setState(() {
                      selectedStation = station;
                      isOverlayVisible = false;
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
    );
  }

  Widget _buildSearchButton() {
    return Positioned(
      top: 40,
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _moveToLocation(LatLng point) {
    const zoomLevel = 15.0;
    if (selectedFromList) {
      mapController.move(point, zoomLevel);
    }
  }

  double _calculateDistance(Position currentPosition, LatLng stationPosition) {
    double distanceInMeters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      stationPosition.latitude,
      stationPosition.longitude,
    );
    return distanceInMeters / 1000;
  }
}
