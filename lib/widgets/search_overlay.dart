// Created 14.03.2024 by Christopher Schilling
//
// This file builds the Search Overlay Widget.
//
// __version__ = "1.0.0"
//
// __author__ = "Christopher Schilling"
//
import 'package:flutter/material.dart';
import 'package:charging_station/models/api.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/helper.dart';
import 'package:easy_localization/easy_localization.dart';

class SearchOverlay extends StatefulWidget {
  final List<ChargingStationInfo> chargingStations;
  final TextEditingController searchController;
  final Position? currentPosition;
  final VoidCallback onClose;
  final void Function(ChargingStationInfo station) onStationSelected;
  final VoidCallback? onFilterTap;

  const SearchOverlay({
    super.key,
    required this.chargingStations,
    required this.searchController,
    required this.currentPosition,
    required this.onClose,
    required this.onStationSelected,
    this.onFilterTap,
  });

  @override
  SearchOverlayState createState() => SearchOverlayState();
}

class SearchOverlayState extends State<SearchOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  Widget build(BuildContext context) {
    List<ChargingStationInfo> filteredStations = widget.chargingStations
        .where((station) =>
            station.city.toLowerCase() == 'potsdam' &&
            station.address
                .toLowerCase()
                .contains(widget.searchController.text.toLowerCase()))
        .toList();

    if (widget.currentPosition != null) {
      filteredStations.sort((a, b) =>
          calculateDistance(widget.currentPosition!, a.coordinates).compareTo(
              calculateDistance(widget.currentPosition!, b.coordinates)));
    } else {
      filteredStations.sort((a, b) => a.address.compareTo(b.address));
    }

    return Positioned.fill(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        color: const Color(0xFF282828),
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
          // Suchfeld mit Filter-Button und Close
          Container(
            height: 60.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.black, width: 2.0),
            ),
            child: Row(
              children: [
                // Filter-Button
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, right: 8.0),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    child: IconButton(
                      icon:
                          const Icon(Icons.filter_list, color: Colors.black87),
                      onPressed: widget.onFilterTap,
                      tooltip: 'filter'.tr(),
                    ),
                  ),
                ),
                // Suchfeld
                Expanded(
                  child: TextField(
                    controller: widget.searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'search'.tr(),
                      contentPadding:
                          const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 15.0),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                // Close-Button
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'close'.tr(),
                  onPressed: () {
                    setState(() {
                      widget.onClose();
                    });
                  },
                ),
              ],
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
                if (widget.currentPosition != null) {
                  double distance = calculateDistance(
                      widget.currentPosition!, station.coordinates);
                  subtitleText = '${formatDistance(distance)} ${'away'.tr()}, ';
                }

                subtitleText += availableCount == 1
                    ? 'one_charger_available'.tr()
                    : 'chargers_available'
                        .tr(args: [availableCount.toString()]);

                return Column(
                  children: [
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
                      onTap: () {
                        setState(() {
                          widget.onStationSelected(station);
                          widget.onClose();
                        });
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
}
