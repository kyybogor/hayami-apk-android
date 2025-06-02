import 'package:flutter/material.dart';
import 'package:hayami_app/Splashscreen/splashscreen.dart';
import 'package:hayami_app/Dashboard/dashboardscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hayami',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      //home: const Splashscreen(),
      home: const Dashboardscreen()
    );
  }
}
