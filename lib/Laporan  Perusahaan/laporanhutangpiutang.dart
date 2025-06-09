import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hayami_app/Dashboard/dashboardscreen.dart';
import 'package:hayami_app/webview/webview.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Laporanhutangpiutang extends StatefulWidget {
  const Laporanhutangpiutang({super.key});

  @override
  State<Laporanhutangpiutang> createState() => _LaporanhutangpiutangState();
}

class _LaporanhutangpiutangState extends State<Laporanhutangpiutang> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse('https://hayami.id/apps/erp/hutang_piutang_android.php'));
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
    'Laporan Hutang Piutang',
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
