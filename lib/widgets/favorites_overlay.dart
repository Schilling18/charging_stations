// Created 14.03.2024 by Christopher Schilling
//
// This file builds the favorites ovelay Widget.
//
// __version__ = "1.0.0"
//
// __author__ = "Christopher Schilling"
//

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:charging_station/models/api.dart';
import 'package:charging_station/utils/helper.dart';

class FavoritesOverlay extends StatelessWidget {
  final List<ChargingStationInfo> favoriteStations;
  final Function(ChargingStationInfo) onStationSelected;
  final VoidCallback onClose;
  final Position? currentPosition;
  final List<ChargingStationInfo> chargingStations;

  const FavoritesOverlay({
    super.key,
    required this.favoriteStations,
    required this.onStationSelected,
    required this.onClose,
    required this.currentPosition,
    required this.chargingStations,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.grey.withOpacity(1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(),
            _buildFavoritesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
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
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Expanded(
      child: favoriteStations.isEmpty
          ? const Center(
              child: Text(
                "Keine Favoriten vorhanden.",
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            )
          : ListView.separated(
              itemCount: favoriteStations.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final station = favoriteStations[index];

                int availableCount = station.evses.values
                    .where((evse) => evse.status == 'AVAILABLE')
                    .length;

                String subtitleText = '';
                if (currentPosition != null) {
                  double distance = calculateDistance(
                    currentPosition!,
                    station.coordinates,
                  );
                  subtitleText = '${formatDistance(distance)} entfernt, ';
                }

                subtitleText += availableCount == 1
                    ? '1 Ladesäule frei'
                    : '$availableCount Ladesäulen frei';

                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        station.address,
                        style: const TextStyle(fontSize: 21.0),
                      ),
                      subtitle: Text(
                        subtitleText,
                        style: const TextStyle(fontSize: 18.0),
                      ),
                      onTap: () {
                        onStationSelected(station);
                        onClose();
                      },
                    ),
                    const SizedBox(height: 16.0),
                  ],
                );
              },
            ),
    );
  }
}
