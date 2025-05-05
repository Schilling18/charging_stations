// Created 14.03.2024 by Christopher Schilling
//
// This file builds the filer overlay Widget.
//
// __version__ = "1.0.0"
//
// __author__ = "Christopher Schilling"
//

import 'package:flutter/material.dart';

class FilterOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const FilterOverlay({super.key, required this.onClose});

  @override
  State<FilterOverlay> createState() => _FilterOverlayState();
}

class _FilterOverlayState extends State<FilterOverlay> {
  final List<String> speedOptions = ['Alle', 'Ab 50kW', 'Ab 150kW', 'Ab 300kW'];
  String selectedSpeed = 'Alle';

  final List<String> plugOptions = [
    'Typ2',
    'CCS',
    'CHAdeMO',
    'SchuKo',
    'Tesla',
    'Andere',
  ];
  Set<String> selectedPlugs = {};

  @override
  Widget build(BuildContext context) {
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
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
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
                        setState(() {
                          selectedSpeed = option;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
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
                        setState(() {
                          if (selected) {
                            selectedPlugs.add(plug);
                          } else {
                            selectedPlugs.remove(plug);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    // Hier könntest du einen Filter-Callback einbauen
                    widget.onClose();
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
  }
}
