import 'package:latlong2/latlong.dart';

class ChargingStationInfo {
  final int id;
  final String name;
  final String address;
  final String chargingSpeed;
  final LatLng point;

  ChargingStationInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.chargingSpeed,
    required this.point,
  });
}

final List<ChargingStationInfo> chargingStations = [
  ChargingStationInfo(
    id: 1,
    name: 'Energie und Wasser Stadtwerke Potsdam Ladestation',
    address: 'Plantagenpl. 4, 14482 Potsdam',
    chargingSpeed: '22 kW',
    point: const LatLng(52.39433483289813, 13.10147618666954),
  ),
  ChargingStationInfo(
    id: 2,
    name: 'Stadtwerke Potsdam Ladestation',
    address: 'Reiherweg 1, 14469 Potsdam',
    chargingSpeed: '22 kW',
    point: const LatLng(52.41232465857877, 13.033464443618108),
  ),
  ChargingStationInfo(
    id: 3,
    name: 'Eneco eMobility Charging Station',
    address: 'Schiffbauergasse 4B, 14467 Potsdam',
    chargingSpeed: '22 kW',
    point: const LatLng(52.40350260308182, 13.072348001020512),
  ),
  ChargingStationInfo(
    id: 4,
    name: 'Allego Ladestation',
    address: 'Zum Kirchsteigfeld 4, 14480 Potsdam',
    chargingSpeed: '150 kW',
    point: const LatLng(52.37159130994981, 13.129320146024778),
  ),
  ChargingStationInfo(
    id: 5,
    name: 'Comfortcharge Ladestation',
    address: 'An d. Alten Zauche, 14478 Potsdam',
    chargingSpeed: '100 kW',
    point: const LatLng(52.37539634885218, 13.09210064080361),
  ),
  ChargingStationInfo(
    id: 6,
    name: 'reev Charging Station',
    address: 'Ulanenweg 2, 14469 Potsdam',
    chargingSpeed: '22 kW',
    point: const LatLng(52.407195840572996, 13.05344481680183),
  ),
  ChargingStationInfo(
    id: 7,
    name: 'Mennekes Charging Station',
    address: 'Konrad-Zuse-Ring 6B, 14469 Potsdam',
    chargingSpeed: '22 kW',
    point: const LatLng(52.433156525494404, 13.057210663126147),
  ),
  ChargingStationInfo(
    id: 8,
    name: 'Stadtwerke Potsdam Ladestation',
    address: 'Nedlitzer Str., 14469 Potsdam',
    chargingSpeed: '22 kW',
    point: const LatLng(52.430693659670936, 13.053163615783413),
  ),
  ChargingStationInfo(
    id: 9,
    name: 'EWP Ladestation',
    address: 'Gutenbergstraße 115, 14467 Potsdam',
    chargingSpeed: '22 kW',
    point: const LatLng(52.40190706517614, 13.048365246979596),
  ),
];
