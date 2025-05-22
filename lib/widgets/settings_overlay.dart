import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(String theme)? onThemeChanged;

  const SettingsOverlay({
    super.key,
    required this.onClose,
    this.onThemeChanged,
  });

  @override
  SettingsOverlayState createState() => SettingsOverlayState();
}

class SettingsOverlayState extends State<SettingsOverlay> {
  late Locale _selectedLocale;
  String selectedTheme = 'Dunkel';

  final Map<String, Locale> languageMap = {
    'Deutsch': const Locale('de'),
    'English': const Locale('en'),
    'Français': const Locale('fr'),
    'Español': const Locale('es'),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale = context.locale;
    _loadTheme();
  }

  Future<void> _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLocale', locale.languageCode);
  }

  Future<void> _saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', theme);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString('selectedTheme');
    if (theme != null && mounted) {
      setState(() {
        selectedTheme = theme;
      });
    }
  }

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
                    Text(
                      "settings".tr(),
                      style: const TextStyle(
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
                Text(
                  "language".tr(),
                  style: const TextStyle(
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
                    child: DropdownButton<Locale>(
                      dropdownColor: const Color(0xFFB2BEB5),
                      value: _selectedLocale,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF282828)),
                      items: languageMap.entries
                          .map((entry) => DropdownMenuItem<Locale>(
                                value: entry.value,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: Color(0xFF282828),
                                    fontSize: 17.0,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (Locale? newLocale) {
                        if (newLocale != null) {
                          setState(() {
                            _selectedLocale = newLocale;
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

                // Design (Theme)
                Text(
                  "design".tr(),
                  style: const TextStyle(
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
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            selectedTheme = value;
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
                Text(
                  "legal".tr(),
                  style: const TextStyle(
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
                  child: Text(
                    "imprint".tr(),
                    style:
                        const TextStyle(color: Color(0xFF282828), fontSize: 17),
                  ),
                ),

                const Spacer(),

                // Anwenden-Button
                ElevatedButton(
                  onPressed: () {
                    context.setLocale(_selectedLocale);
                    if (widget.onThemeChanged != null) {
                      widget.onThemeChanged!(selectedTheme);
                    }
                    widget.onClose();
                    _saveLocale(_selectedLocale);
                    _saveTheme(selectedTheme);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2BEB5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'apply'.tr(),
                    style:
                        const TextStyle(color: Color(0xFF282828), fontSize: 18),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
