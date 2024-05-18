import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class EvseInfo {
  final String evseNumber;
  final int maxPower;
  final String status;

  EvseInfo({
    required this.evseNumber,
    required this.maxPower,
    required this.status,
  });
}

class ChargingStationInfo {
  final String id;
  final String address;
  final String city;
  final LatLng coordinates;
  final int freechargers;
  final Map<String, EvseInfo> evses;

  ChargingStationInfo({
    required this.id,
    required this.address,
    required this.city,
    required this.coordinates,
    required this.freechargers,
    required this.evses,
  });

  factory ChargingStationInfo.fromJson(Map<String, dynamic> json) {
    Map<String, EvseInfo> evsesMap = {};
    Set<String> uniqueAvailableEvseNumbers =
        {}; // Set zur Aufbewahrung eindeutiger verfügbarer EVSE-Nummern

    for (var evse in json['evses']) {
      for (var connector in evse['connectors']) {
        evsesMap[evse['id']] = EvseInfo(
          evseNumber: evse['id'],
          maxPower: connector['max_power'],
          status: evse['status'],
        );
        if (evse['status'] == 'AVAILABLE') {
          uniqueAvailableEvseNumbers
              .add(evse['id']); // Füge eindeutige verfügbare EVSE-Nummern hinzu
        }
      }
    }

    return ChargingStationInfo(
      id: json['id'],
      address: json['address'],
      city: json['city'],
      coordinates: LatLng(
        double.parse(json['coordinates']['latitude']),
        double.parse(json['coordinates']['longitude']),
      ),
      freechargers: uniqueAvailableEvseNumbers
          .length, // Setzen der Anzahl eindeutiger verfügbarer Ladegeräte
      evses: evsesMap,
    );
  }
}

Future<List<ChargingStationInfo>> fetchChargingStations() async {
  final response = await http.get(
    Uri.parse('https://cs1-swp.westeurope.cloudapp.azure.com:8443/chargers'),
    headers: {'X-Api-Key': '6bcadbac-976e-4d6b-a593-f925fba25506'},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);

    if (data.containsKey('data')) {
      final List<dynamic> stations = data['data'];

      List<ChargingStationInfo> chargingStations = [];

      for (var station in stations) {
        chargingStations.add(ChargingStationInfo.fromJson(station));
      }

      return chargingStations;
    } else {
      throw Exception('No data key found in response');
    }
  } else {
    throw Exception('Failed to load charging stations');
  }
}

void main() async {
  try {
    List<ChargingStationInfo> chargingStations = await fetchChargingStations();
    for (var station in chargingStations) {
      print('Adresse: ${station.address}');
      print('City: ${station.city}');
      print('Coordinates: ${station.coordinates}');
      print('Free Chargers: ${station.freechargers}');
      print('EVSEs:');
      station.evses.forEach((evseNumber, evseInfo) {
        print('  EVSE Number: ${evseInfo.evseNumber}');
        print('  Max Power: ${evseInfo.maxPower}');
        print('  Status: ${evseInfo.status}');
        print('   ----');
      });
      print('-------------------------------------');
    }
  } catch (e) {
    print('Error: $e');
  }
}
