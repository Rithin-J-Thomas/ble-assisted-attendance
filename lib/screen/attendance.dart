import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dates = snapshot.data!.docs;

          return ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final dateDoc = dates[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text("Date: ${dateDoc.id}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
