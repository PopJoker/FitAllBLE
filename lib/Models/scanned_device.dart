import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScannedDevice {
  final BluetoothDevice device;
  int rssi;

  ScannedDevice({
    required this.device,
    required this.rssi,
  });
}
