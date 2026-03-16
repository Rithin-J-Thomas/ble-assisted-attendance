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
  final List<String> _detectedStudents = [];

  final TextEditingController _rssiController = TextEditingController(
    text: "-75",
  );

  final TextEditingController _subjectController = TextEditingController();
  String subject = "";

  bool _isScanning = false;

  int rssiThreshold = -75;

  String? _currentSession;

  @override
  void dispose() {
    _scanSub?.cancel();
    _rssiController.dispose();
    _subjectController.dispose();
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

    final now = DateTime.now();

    final today =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

    if (_currentSession == null) return;

    final session = _currentSession!;

    final attendanceRef = FirebaseFirestore.instance
        .collection('attendance')
        .doc(today)
        .collection(subject)
        .doc(session)
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

  void _stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;

    setState(() {
      _isScanning = false;
    });

    debugPrint("Scanning stopped");
  }

  void _updateRssi() {
    final value = int.tryParse(_rssiController.text);

    if (value != null) {
      setState(() {
        rssiThreshold = value;
      });
      debugPrint("New RSSI threshold: $rssiThreshold");
    }
  }

  void _startScan() async {
    subject = _subjectController.text.trim();

    if (subject.isEmpty) {
      debugPrint("Subject is empty");
      return;
    }

    _markedStudents.clear();
    _detectedStudents.clear();

    final now = DateTime.now();

    _currentSession =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final granted = await _requestPermissions();
    if (!granted) {
      debugPrint('Permissions denied, cannot scan.');
      return;
    }
    setState(() {
      _isScanning = true;
    });

    _scanSub?.cancel();

    final myServiceUuid = Uuid.parse("12345678-1234-1234-1234-1234567890ab");

    _scanSub = _ble
        .scanForDevices(
          withServices: [myServiceUuid], // 👈 FILTER HERE
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          (device) {
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
                debugPrint(
                  "Ignored weak signal: $rollNo | RSSI ${device.rssi}",
                );
                return;
              }

              debugPrint("Detected Student: $rollNo | RSSI: ${device.rssi}");

              if (!_detectedStudents.contains(rollNo)) {
                setState(() {
                  _detectedStudents.add(rollNo);
                });
              }

              markAttendance(rollNo, deviceId);
            } catch (e) {
              debugPrint("Decode failed: $e");
            }
          },
          onError: (e) {
            debugPrint('Scan error: $e');
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Mode')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: "Subject (example: Maths)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),


            TextField(
              controller: _rssiController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Minimum RSSI (example: -60)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _updateRssi,
              child: const Text("Set RSSI Threshold"),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 80)),
              onPressed: _isScanning ? null : _startScan,
              child: const Text("Start Scan"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 80),
                backgroundColor: Colors.red,
              ),
              onPressed: _isScanning ? _stopScan : null,
              child: const Text("Stop Scan"),
            ),

            const SizedBox(height: 30),

            Text(
              "Detected Students (${_detectedStudents.length})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: _detectedStudents.length,
                itemBuilder: (context, index) {
                  final roll = _detectedStudents[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text("Roll No: $roll"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
