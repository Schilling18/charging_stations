// Created 14.03.2024 by Christopher Schilling
//
// This file builds the favorites overlay Widget.
//
// __version__ = "1.0.1"
//
// __author__ = "Christopher Schilling"
//
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:charging_station/models/api.dart';
import 'package:charging_station/utils/helper.dart';
import 'package:easy_localization/easy_localization.dart';

class FavoritesOverlay extends StatelessWidget {
  final List<ChargingStationInfo> favoriteStations;
  final Function(ChargingStationInfo) onStationSelected;
  final VoidCallback onClose;
  final Position? currentPosition;
  final List<ChargingStationInfo> chargingStations;
  final Function(String) onDeleteFavorite;

  const FavoritesOverlay({
    super.key,
    required this.favoriteStations,
    required this.onStationSelected,
    required this.onClose,
    required this.currentPosition,
    required this.chargingStations,
    required this.onDeleteFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF282828),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(context),
            _buildFavoritesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 32.0,
        left: 16.0,
        right: 16.0,
        bottom: 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "favorites".tr(),
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB2BEB5),
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.close, color: Color(0xFFB2BEB5), size: 28),
                onPressed: onClose,
              ),
            ],
          ),
          const Divider(
            color: Color(0xFFB2BEB5),
            thickness: 1.0,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context) {
    return Expanded(
      child: favoriteStations.isEmpty
          ? Center(
              child: Text(
                "no_favorites".tr(),
                style: const TextStyle(color: Color(0xFFB2BEB5), fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: favoriteStations.length,
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
                  subtitleText = '${formatDistance(distance)} ${"away".tr()}, ';
                }

                subtitleText += availableCount == 1
                    ? "one_charger_available".tr()
                    : tr('chargers_available',
                        args: [availableCount.toString()]);

                return Column(
                  children: [
                    if (index > 0) ...[
                      const Divider(
                        color: Color(0xFFB2BEB5),
                        thickness: 1.0,
                        height: 0,
                      ),
                      const SizedBox(height: 14),
                    ],
                    ListTile(
                      title: Text(
                        station.address,
                        style: const TextStyle(
                          fontSize: 21.0,
                          color: Color(0xFFB2BEB5),
                        ),
                      ),
                      subtitle: Text(
                        subtitleText,
                        style: const TextStyle(
                          fontSize: 18.0,
                          color: Color(0xFFB2BEB5),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close,
                            color: Color(0xFFB2BEB5), size: 26),
                        onPressed: () =>
                            onDeleteFavorite(station.id.toString()),
                        tooltip: "remove_favorite".tr(),
                      ),
                      onTap: () {
                        onStationSelected(station);
                        onClose();
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
