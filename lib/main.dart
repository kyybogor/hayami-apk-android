import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hayami_app/Splashscreen/splashscreen.dart';
import 'package:hayami_app/Dashboard/dashboardscreen.dart';
import 'package:hayami_app/pos/posscreen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Inisialisasi untuk Web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Inisialisasi untuk Desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
      home: const Splashscreen(),
      //home: const Dashboardscreen()
      // home: const Posscreen(),
    );
  }
}
