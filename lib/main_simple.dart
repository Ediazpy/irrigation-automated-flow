import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('IrriTrack Test'),
        ),
        body: const Center(
          child: Text(
            'Hello! App is working!',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
