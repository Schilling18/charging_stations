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
    Set<String> uniqueAvailableEvseNumbers = {};

    for (var evse in json['evses']) {
      for (var connector in evse['connectors']) {
        evsesMap[evse['id']] = EvseInfo(
          evseNumber: evse['id'],
          maxPower: connector['max_power'],
          status: evse['status'],
        );
        if (evse['status'] == 'AVAILABLE') {
          uniqueAvailableEvseNumbers.add(evse['id']);
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
      freechargers: uniqueAvailableEvseNumbers.length,
      evses: evsesMap,
    );
  }
}

class ApiService {
  final String _baseUrl =
      'https://cs1-swp.westeurope.cloudapp.azure.com:8443/chargers';
  final String _apiKey = '6bcadbac-976e-4d6b-a593-f925fba25506';

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
