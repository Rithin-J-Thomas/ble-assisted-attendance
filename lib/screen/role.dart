import 'package:flutter/material.dart';
import 'package:blee/screen/teacher.dart';
import 'package:blee/screen/student.dart';

class RolePage extends StatelessWidget {
  const RolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade100,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size(190, 90)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const Student(),
                  ),
                );
              },
              child: const Text('STUDENT'),
            ),
            const SizedBox(height: 90),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size(190, 90)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const Teacher(),
                  ),
                );
              },
              child: const Text('TEACHER'),
            ),
          ],
        ),
      ),
    );
  }
}
