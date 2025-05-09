// Created 14.03.2024 by Christopher Schilling
//
// This file builds the station details Widget.
//
// __version__ = "1.0.0"
//
// __author__ = "Christopher Schilling"
//

import 'package:flutter/material.dart';
import 'package:charging_station/models/api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/helper.dart';

class StationDetailsWidget extends StatelessWidget {
  final ChargingStationInfo selectedStation;
  final bool isFavorite;
  final Function(String) toggleFavorite;
  final Function() onDismiss;
  final Position? currentPosition;

  const StationDetailsWidget({
    required this.selectedStation,
    required this.isFavorite,
    required this.toggleFavorite,
    required this.onDismiss,
    this.currentPosition,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 0) {
          onDismiss();
        }
      },
      child: Dismissible(
        key: const ValueKey("dismissible"),
        direction: DismissDirection.down,
        onDismissed: (_) => onDismiss(),
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
                        selectedStation.address,
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              launchUrl(Uri.parse(
                                'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(selectedStation.address)}',
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
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

                          // ✅ Neue Statusanzeige
                          Builder(
                            builder: (context) {
                              final availableCount = selectedStation
                                  .evses.values
                                  .where((evse) => evse.status == 'AVAILABLE')
                                  .length;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: availableCount > 0
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  availableCount > 0
                                      ? '$availableCount Verfügbar'
                                      : 'Nicht verfügbar',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 10.0),

                          ElevatedButton(
                            onPressed: () {
                              toggleFavorite(selectedStation.id.toString());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isFavorite ? Colors.green : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                            ),
                            child: Text(
                              isFavorite ? 'Favorit' : 'Favorisieren',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                if (currentPosition != null)
                  Center(
                    child: Text(
                      'Entfernung: ${formatDistance(calculateDistance(currentPosition!, selectedStation.coordinates))}',
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
                            in selectedStation.evses.values.toList()
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
                                  Icon(
                                    Icons.circle,
                                    color: evse.status == 'AVAILABLE'
                                        ? Colors.green
                                        : Colors.red,
                                    size: 24.0,
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
                                        style: const TextStyle(fontSize: 20.0),
                                      ),
                                      Text(
                                        '${evse.maxPower} kW',
                                        style: const TextStyle(fontSize: 20.0),
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
    );
  }
}
