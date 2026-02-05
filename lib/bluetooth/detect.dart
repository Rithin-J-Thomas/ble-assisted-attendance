import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleDetection {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  Stream<DiscoveredDevice> startScan() {
    return _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    );
  }
}
