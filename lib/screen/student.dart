import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Student extends StatefulWidget {
  const Student({super.key});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> {

  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final TextEditingController _rollController = TextEditingController();

  bool isAdvertising = false;

  String? deviceId;
  String? rollNo;

  @override
  void initState() {
    super.initState();
    _loadRegistration();
  }

  Future<void> _loadRegistration() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      rollNo = prefs.getString("rollNo");
      deviceId = prefs.getString("deviceId");
    });

    if (rollNo != null) {
      _rollController.text = rollNo!;
    }
  }

  Future<void> _registerDevice() async {
    final prefs = await SharedPreferences.getInstance();

    final roll = _rollController.text.trim();
    if (roll.isEmpty) return;

    const uuid = Uuid();
    final newDeviceId = uuid.v4();

    await prefs.setString("rollNo", roll);
    await prefs.setString("deviceId", newDeviceId);

    setState(() {
      rollNo = roll;
      deviceId = newDeviceId;
    });

    debugPrint("Registered DeviceID: $deviceId");
  }

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

    if (rollNo == null || deviceId == null) {
      debugPrint("Device not registered");
      return;
    }

    final payload = "$rollNo|$deviceId";

    final advertiseData = AdvertiseData(
      serviceUuid: "12345678-1234-1234-1234-1234567890ab",
      manufacturerId: 1234,
      manufacturerData: utf8.encode(payload),
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

    debugPrint("Advertising: $payload");

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

    final registered = rollNo != null && deviceId != null;

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
              enabled: !registered,
            ),

            const SizedBox(height: 20),

            if (!registered)
              ElevatedButton(
                onPressed: _registerDevice,
                child: const Text("Register Device"),
              ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 80),
              ),
              onPressed: registered
                  ? (isAdvertising ? _stopAdvertising : _startAdvertising)
                  : null,
              child: Text(isAdvertising ? "STOP" : "PRESENT"),
            ),
          ],
        ),
      ),
    );
  }
}
