// Created 14.03.2024 by Christopher Schilling
//
// This file builds the settings overlay Widget.
//
// __version__ = "1.0.1"
//
// __author__ = "Christopher Schilling"
//
import 'package:flutter/material.dart';

class SettingsOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const SettingsOverlay({super.key, required this.onClose});

  @override
  SettingsOverlayState createState() => SettingsOverlayState();
}

class SettingsOverlayState extends State<SettingsOverlay> {
  String selectedLanguage = 'Deutsch';
  String selectedTheme = 'Dunkel';

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: const Color(0xFF282828),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Überschrift + Schließen-Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Einstellungen",
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
                const Divider(color: Color(0xFFB2BEB5)),
                const SizedBox(height: 10),

                // Sprache
                const Text(
                  'Sprache',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB2BEB5),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2BEB5),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFFB2BEB5),
                      value: selectedLanguage,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF282828)),
                      items: ['Deutsch', 'Englisch', 'Französisch', 'Spanisch']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: Color(0xFF282828),
                              fontSize: 17.0,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedLanguage = newValue;
                          });
                        }
                      },
                      style: const TextStyle(
                        color: Color(0xFF282828),
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Design (Theme Mode)
                const Text(
                  'Design',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB2BEB5),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2BEB5),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFFB2BEB5),
                      value: selectedTheme,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF282828)),
                      items: ['Hell', 'Dunkel'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: Color(0xFF282828),
                              fontSize: 17.0,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedTheme = newValue;
                          });
                        }
                      },
                      style: const TextStyle(
                        color: Color(0xFF282828),
                        fontSize: 17.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Impressum
                const Text(
                  'Rechtliches',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB2BEB5),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2BEB5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Impressum',
                    style: TextStyle(color: Color(0xFF282828), fontSize: 17),
                  ),
                ),

                const Spacer(),

                ElevatedButton(
                  onPressed: () {
                    widget.onClose();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2BEB5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Anwenden',
                    style: TextStyle(color: Color(0xFF282828), fontSize: 18),
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
