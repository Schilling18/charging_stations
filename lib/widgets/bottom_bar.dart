// Created 14.03.2024 by Christopher Schilling
//
// This file builds the BottomBar Widget.
//
// __version__ = "1.0.0"
//
// __author__ = "Christopher Schilling"
//

import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  final VoidCallback onFavoritesTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onFilterTap;

  const BottomBar({
    super.key,
    required this.onFavoritesTap,
    required this.onSettingsTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      color: const Color(0xFF282828),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildBottomButton(
              label: 'Favoriten',
              onPressed: onFavoritesTap,
            ),
            _buildBottomButton(
              label: 'Einstellungen',
              onPressed: onSettingsTap,
            ),
            _buildBottomButton(
              label: 'Filter',
              onPressed: onFilterTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(
      {required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16.0,
          color: Colors.black,
        ),
      ),
    );
  }
}
