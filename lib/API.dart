import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Class representing an Electric Vehicle Supply Equipment (EVSE).
class EvseInfo {
  final String evseNumber;
  final int maxPower;
  final String status;
  final bool illegallyParked;

  EvseInfo({
    required this.evseNumber,
    required this.maxPower,
    required this.status,
    required this.illegallyParked,
  });
}

/// Class representing a Charging Station.
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

  /// Factory constructor to create an instance of ChargingStationInfo from JSON
  /// Checks if a car is charging at the charging station, and if a car is illegally stopping without actually charging.
  factory ChargingStationInfo.fromJson(Map<String, dynamic> json) {
    Map<String, EvseInfo> evsesMap = {};
    Set<String> uniqueAvailableEvseNumbers = {};

    for (var evse in json['evses']) {
      for (var connector in evse['connectors']) {
        bool illegallyParked = false;
        String status = evse['status'];

        if (evse.containsKey('parking_sensor') &&
            evse['parking_sensor'] is Map) {
          var parkingSensor = evse['parking_sensor'] as Map<String, dynamic>;
          illegallyParked = parkingSensor['illegally_parked'] ?? false;
        }

        if (status == 'AVAILABLE' && !illegallyParked) {
          uniqueAvailableEvseNumbers.add(evse['id']);
        }

        evsesMap[evse['id']] = EvseInfo(
          evseNumber: evse['id'],
          maxPower: connector['max_power'],
          status: status,
          illegallyParked: illegallyParked,
        );
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
      freechargers: uniqueAvailableEvseNumbers.length,
      evses: evsesMap,
    );
  }
}

/// Service class for API interactions.
class ApiService {
  final String _baseUrl =
      'https://cs1-swp.westeurope.cloudapp.azure.com:8443/chargers';
  final String _apiKey = '6bcadbac-976e-4d6b-a593-f925fba25506';

  /// Fetches the list of charging stations from the API.
  Future<List<ChargingStationInfo>> fetchChargingStations() async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {'X-Api-Key': _apiKey},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.containsKey('data')) {
        final List<dynamic> stations = data['data'];

        return stations
            .map((station) => ChargingStationInfo.fromJson(station))
            .toList();
      } else {
        throw Exception('No data key found in response');
      }
    } else {
      throw Exception('Failed to load charging stations');
    }
  }

  /// Searches for an address using the OpenStreetMap Nominatim API.
  Future<List<dynamic>> searchAddress(String query) async {
    final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=1&countrycodes=de'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error: ${response.reasonPhrase}');
    }
  }
}

/// Used for debugging.
void main() async {
  final apiService = ApiService();
  try {
    final stations = await apiService.fetchChargingStations();
    for (var station in stations) {
      print('ID: ${station.id}');
      print('Address: ${station.address}');
      print('City: ${station.city}');
      print(
          'Coordinates: ${station.coordinates.latitude}, ${station.coordinates.longitude}');
      print('Free Chargers: ${station.freechargers}');
      print('EVSEs:');
      for (var evse in station.evses.values) {
        print('  EVSE Number: ${evse.evseNumber}');
        print('  Max Power: ${evse.maxPower}');
        print('  Status: ${evse.status}');
        print('  Illegally Parked: ${evse.illegallyParked}');
      }
      print('---');
    }
  } catch (e) {
    print('Error: $e');
  }
}
