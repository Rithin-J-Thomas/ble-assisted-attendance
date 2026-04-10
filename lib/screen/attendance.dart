import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  void _openDate(BuildContext context, String date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DateDetailPage(date: date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Attendance Found"));
          }

          final dates = snapshot.data!.docs;

          return ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final dateDoc = dates[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text("Date: ${dateDoc.id}"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _openDate(context, dateDoc.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DateDetailPage extends StatefulWidget {
  final String date;

  const DateDetailPage({super.key, required this.date});

  @override
  State<DateDetailPage> createState() => _DateDetailPageState();
}

class _DateDetailPageState extends State<DateDetailPage> {

  List<Map<String, dynamic>> records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {

    try {
      records.clear();

      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('students')
          .get();

      for (var doc in querySnapshot.docs) {

        final data = doc.data();

        final sessionRef = doc.reference.parent.parent;
        final subjectRef = sessionRef?.parent;
        final dateRef = subjectRef?.parent;

        // ✅ Filter by selected date
        if (dateRef == null || dateRef.id != widget.date) continue;

        records.add({
          "rollNo": data["rollNo"] ?? "Unknown",
          "time": sessionRef?.id ?? "Unknown",
          "subject": subjectRef?.id ?? "Unknown",
        });
      }

    } catch (e) {
      debugPrint("Error fetching attendance: $e");
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Date: ${widget.date}"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
          ? const Center(child: Text("No records found"))
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {

          final item = records[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text("Roll No: ${item["rollNo"]}"),
              subtitle: Text(
                "Subject: ${item["subject"]}\nTime: ${item["time"]}",
              ),
            ),
          );
        },
      ),
    );
  }
}
