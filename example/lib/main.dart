import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_dltime/fw_dltime.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _fwRevision = 'CSLBL.072.202';
  final _fwDltimePlugin = FwDltime(debug: true);
  late double _downloadTime;
  late double _downloadSpeed;
  late int _fwFlashSize;

  @override
  void initState() {
    super.initState();
    initPlatformState();

    _fwDltimePlugin.getDownloadTime(
      fwRevision: _fwRevision,
      callback: (double dlSpeed, int fwSize, double time, String? error) {
        if (null != error) {
          debugPrint('=======> error: $error');
        }

        if (!mounted) return;

        setState(() {
          _downloadSpeed = dlSpeed;
          _fwFlashSize = fwSize;
          _downloadTime = time;
        });
      },
    );
  }

  @override
  void dispose() {
    _fwDltimePlugin.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _fwDltimePlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              Text(
                  'Download Speed: ${_downloadSpeed.toStringAsFixed(2)} Mbps\n'),
              Text('FW Revision: $_fwRevision\n'),
              Text('Flash file size: $_fwFlashSize\n'),
              Text(
                  'Estimated download time: ${_downloadTime.toStringAsFixed(2)} Mbps\n'),
            ],
          ),
        ),
      ),
    );
  }
}
