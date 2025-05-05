// Created 14.03.2024 by Christopher Schilling
//
// This is the Main file
//
// __version__ = "1.3.0"
//
// __author__ = "Christopher Schilling"
//

import 'package:flutter/material.dart';
import 'screen/map_screen.dart';

void main() {
  runApp(const ChargingStationApp());
}

class ChargingStationApp extends StatelessWidget {
  const ChargingStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
