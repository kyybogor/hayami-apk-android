import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse('https://www.instagram.com/'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView - Google')),
      body: kIsWeb
          ? const Center(child: Text('WebView tidak tersedia di platform Web'))
          : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : WebViewWidget(controller: _controller!),
    );
  }
}
