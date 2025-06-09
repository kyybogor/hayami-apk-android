import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hayami_app/Dashboard/dashboardscreen.dart';
import 'package:hayami_app/webview/webview.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Laporanaruskas extends StatefulWidget {
  const Laporanaruskas({super.key});

  @override
  State<Laporanaruskas> createState() => _LaporanaruskasState();
}

class _LaporanaruskasState extends State<Laporanaruskas> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse('https://hayami.id/apps/erp/akuntan_arus_kas_android.php'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  iconTheme: const IconThemeData(color: Colors.black),
  title: const Text(
    'Laporan Arus Kas',
    style: TextStyle(color: Colors.blue),
  ),
  centerTitle: true,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Laporanperusahaan()),
      );
    },
  ),
),

      body: kIsWeb
          ? const Center(child: Text('WebView tidak tersedia di platform Web'))
          : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : WebViewWidget(controller: _controller!),
    );
  }
}
