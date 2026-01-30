import 'package:flutter/material.dart';

class Teacher extends StatelessWidget {
  const Teacher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Mode')),
      body: const Center(
        child: Text('Hello Teacher', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class HelloPage extends StatelessWidget {
  const HelloPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Helo', style: TextStyle(fontSize: 24))),
    );
  }
}
