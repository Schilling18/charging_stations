import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'marker.dart';

void main() {
  runApp(const ChargingStationApp());
}

class ChargingStationApp extends StatelessWidget {
  const ChargingStationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChargingStation(),
    );
  }
}

class ChargingStation extends StatefulWidget {
  const ChargingStation({Key? key}) : super(key: key);

  @override
  _ChargingStationState createState() => _ChargingStationState();
}

class _ChargingStationState extends State<ChargingStation> {
  ChargingStationInfo? selectedStation;
  bool isOverlayVisible = false;
  bool selectedFromList = false;
  late MapController _mapController;
  TextEditingController searchController = TextEditingController();
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _checkLocationPermission();
    _initializeMapLocation();
  }

  void _checkLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      await Permission.locationWhenInUse.request();
    }

    _initializeMapLocation();
  }

  void _initializeMapLocation() async {
    LatLng initialPosition = const LatLng(52.390568, 13.064472);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        try {
          Position position = await Geolocator.getCurrentPosition();
          initialPosition = LatLng(position.latitude, position.longitude);
          currentPosition = position;
        } catch (e) {
          print("Error getting current position: $e");
        }
      }
    }

    setState(() {
      _mapController.move(initialPosition, 12.0);
    });
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
                mapController: _mapController,
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
                        .map((station) => Marker(
                              width: 40.0,
                              height: 40.0,
                              point: station.point,
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
            if (selectedStation != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
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
                            child: Text(
                              selectedStation!.name,
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Divider(
                            color: Colors.grey,
                            thickness: 1.0,
                          ),
                          const SizedBox(height: 20.0),
                          Center(
                            child: Text(
                              selectedStation!.address,
                              style: const TextStyle(
                                fontSize: 18.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Center(
                            child: Text(
                              selectedStation!.chargingSpeed,
                              style: const TextStyle(fontSize: 18.0),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Anzeige der Distanz zum aktuellen Standort
                          if (currentPosition != null &&
                              selectedStation != null)
                            Center(
                              child: Text(
                                'Distanz: ${_calculateDistance(currentPosition!, selectedStation!.point).toStringAsFixed(2)} km',
                                style: const TextStyle(fontSize: 18.0),
                                textAlign: TextAlign.center,
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (isOverlayVisible) _buildSearchOverlay(),
            if (!isOverlayVisible)
              Positioned(
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
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
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
              ),
          ],
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
                        setState(() {
                          // Update the list whenever the text in the TextField changes
                          // You can apply your filtering logic here
                        });
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
                    _moveToLocation(station.point);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _moveToLocation(LatLng point) {
    const zoomLevel = 15.0;
    if (selectedFromList) {
      _mapController.move(point, zoomLevel);
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
