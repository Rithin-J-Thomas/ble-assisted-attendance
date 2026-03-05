import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';

class Student extends StatefulWidget {
  const Student({super.key});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> {

  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final TextEditingController _rollController = TextEditingController();

  bool isAdvertising = false;

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _startAdvertising() async {
    await _requestPermissions();

    final rollNo = _rollController.text.trim();
    if (rollNo.isEmpty) return;

    final advertiseData = AdvertiseData(
      serviceUuid: "12345678-1234-1234-1234-1234567890ab",
      manufacturerId: 1234,
      manufacturerData: utf8.encode(rollNo),
      includeDeviceName: false,
    );

    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      connectable: false,
    );

    await _blePeripheral.start(
      advertiseData: advertiseData,
      advertiseSettings: settings,
    );

    setState(() {
      isAdvertising = true;
    });
  }

  Future<void> _stopAdvertising() async {
    await _blePeripheral.stop();
    setState(() {
      isAdvertising = false;
    });
  }

  @override
  void dispose() {
    _rollController.dispose();
    _blePeripheral.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Mode")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _rollController,
              decoration: const InputDecoration(
                labelText: "Enter Roll Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 80),
              ),
              onPressed: isAdvertising
                  ? _stopAdvertising
                  : _startAdvertising,
              child: Text(isAdvertising ? "STOP" : "PRESENT"),
            ),
          ],
        ),
      ),
    );
  }
}
