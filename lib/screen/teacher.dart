import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';



class Teacher extends StatefulWidget {
  const Teacher({super.key});

  @override
  State<Teacher> createState() => _TeacherState();
}

class _TeacherState extends State<Teacher> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSub;

    final Set<String> _markedStudents = {};
    static const int rssiThreshold = -75;


  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> markAttendance(String rollNo, String deviceId) async {

    if (_markedStudents.contains(rollNo)) {
      debugPrint("Already marked locally: $rollNo");
      return;
    }

    final studentDoc = await FirebaseFirestore.instance
        .collection('student')
        .doc(rollNo)
        .get();

    if (!studentDoc.exists) {
      debugPrint("Student not registered");
      return;
    }

    final data = studentDoc.data()!;

    if (data['deviceId'] != deviceId) {
      debugPrint("Device ID mismatch");
      return;
    }

    if (data['approved'] != true) {
      debugPrint("Student not approved");
      return;
    }

    final today = DateTime.now().toIso8601String().split("T")[0];

    final attendanceRef = FirebaseFirestore.instance
        .collection('attendance')
        .doc(today)
        .collection('students')
        .doc(rollNo);

    final doc = await attendanceRef.get();

    if (doc.exists) {
      debugPrint("Attendance already exists in DB");
      _markedStudents.add(rollNo);
      return;
    }

    await attendanceRef.set({
      "rollNo": rollNo,
      "deviceId": deviceId,
      "present": true,
      "time": FieldValue.serverTimestamp(),
    });

    _markedStudents.add(rollNo);

    debugPrint("Attendance marked for $rollNo");
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

    _markedStudents.clear();

    final granted = await _requestPermissions();
    if (!granted) {
      debugPrint('Permissions denied, cannot scan.');
      return;
    }

    _scanSub?.cancel();

    final myServiceUuid =
    Uuid.parse("12345678-1234-1234-1234-1234567890ab");

    _scanSub = _ble
        .scanForDevices(
      withServices: [myServiceUuid], // 👈 FILTER HERE
      scanMode: ScanMode.lowLatency,
    )
        .listen((device) {

      final data = device.manufacturerData;

      if (data.length <= 2) return; // must contain ID + data

      try {
        final payloadBytes = data.sublist(2);
        final payload = utf8.decode(payloadBytes);

        final parts = payload.split("|");

        if (parts.length != 2) return;

        final rollNo = parts[0];
        final deviceId = parts[1];

        if (device.rssi < rssiThreshold) {
          debugPrint("Ignored weak signal: $rollNo | RSSI ${device.rssi}");
          return;
        }

        debugPrint("Detected Student: $rollNo | RSSI: ${device.rssi}");

        markAttendance(rollNo, deviceId);


      } catch (e) {
        debugPrint("Decode failed: $e");
      }

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
