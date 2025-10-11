import 'package:flutter/material.dart';

void main() {
  runApp(const McdPointTrackerApp());
}

class McdPointTrackerApp extends StatelessWidget {
  const McdPointTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'McD Point Tracker',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(child: Text('McD Point Tracker')),
      ),
    );
  }
}
