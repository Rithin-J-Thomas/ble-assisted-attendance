import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';


class Teacher extends StatefulWidget {
  const Teacher({super.key});

  @override
  State<Teacher> createState() => _TeacherState();
}

class _TeacherState extends State<Teacher> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSub;

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // optional
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  void _startScan() async {
    final granted = await _requestPermissions();
    if (!granted) {
      debugPrint('Permissions denied, cannot scan.');
      return;
    }

    _scanSub?.cancel();
    _scanSub = _ble.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency)
        .listen((device) {
      debugPrint('Found: ${device.name.isNotEmpty ? device.name : "Unknown"} '
          '(${device.manufacturerData}) RSSI: ${device.rssi}');
    }, onError: (e) {
      debugPrint('Scan error: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Mode')),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            minimumSize: const Size(190, 90),
          ),
          onPressed: _startScan,
          child: const Text("Start Scan"),
        ),
      ),
    );
  }
}
