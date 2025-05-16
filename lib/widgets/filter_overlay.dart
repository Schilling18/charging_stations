// Created 14.03.2024 by Christopher Schilling
//
// This file builds the filter overlay Widget.
//
// __version__ = "1.0.2"
//
// __author__ = "Christopher Schilling"
//
import 'package:flutter/material.dart';
import 'package:charging_station/utils/helper.dart';

class FilterOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const FilterOverlay({super.key, required this.onClose});

  @override
  State<FilterOverlay> createState() => _FilterOverlayState();
}

class _FilterOverlayState extends State<FilterOverlay> {
  final List<String> speedOptions = [
    'Alle',
    'Bis 50kW',
    'Ab 50kW',
    'Ab 100kW',
    'Ab 200kW',
    'Ab 300kW'
  ];
  String selectedSpeed = 'Alle';

  final List<String> plugOptions = [
    'Typ2',
    'CCS',
    'CHAdeMO',
    'Tesla',
  ];
  Set<String> selectedPlugs = {};

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
  }

  Future<void> _loadSavedFilters() async {
    final speed = await loadSelectedSpeed();
    final plugs = await loadSelectedPlugs();

    setState(() {
      selectedSpeed = speed;
      selectedPlugs = plugs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF282828),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Filter",
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB2BEB5),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Color(0xFFB2BEB5), size: 28),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(
                  color: Color(0xFFB2BEB5),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ladegeschwindigkeit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB2BEB5),
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: speedOptions.map((option) {
                    final isSelected = selectedSpeed == option;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ChoiceChip(
                        label: Text(option),
                        selected: isSelected,
                        selectedColor: Colors.green,
                        backgroundColor: const Color(0xFFB2BEB5),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        onSelected: (_) {
                          setState(() {
                            selectedSpeed = option;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Stecker',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB2BEB5),
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: plugOptions.map((plug) {
                    final isSelected = selectedPlugs.contains(plug);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: FilterChip(
                        label: Text(plug),
                        selected: isSelected,
                        selectedColor: Colors.green,
                        backgroundColor: const Color(0xFFB2BEB5),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedPlugs.add(plug);
                            } else {
                              selectedPlugs.remove(plug);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await saveSelectedSpeed(selectedSpeed);
                    await saveSelectedPlugs(selectedPlugs);
                    widget.onClose();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Filter anwenden',
                    style: TextStyle(color: Color(0xFFB2BEB5), fontSize: 18),
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
