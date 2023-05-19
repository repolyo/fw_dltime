import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_dltime/fw_dltime.dart';

import 'firebase_options.dart';

const kBodyContainerDecoration = BoxDecoration(
  border: Border(
    top: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _messageController = TextEditingController();

  String _platformVersion = 'Unknown';
  String _fwRevision = 'CSLBL.072.202';
  FwDltime? _fwDltimePlugin;
  String? _error;
  double _downloadTime = 0.0;
  double _downloadSpeed = 0.0;
  String _message = 'Fetching file size...';
  int _percentage = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _fwDltimePlugin?.dispose();
    super.dispose();
  }

  calculateDownloadTime(fwRevision) {
    _fwDltimePlugin?.dispose();
    _fwRevision = fwRevision;
    _fwDltimePlugin = FwDltime(debug: true, fwRevision: _fwRevision);

    _fwDltimePlugin?.calculateDownloadTime((percentage, dlSpeed, time, error) {
      if (!mounted || 0 == percentage) return;

      setState(() {
        _error = 100 == _percentage ? null : error;
        _percentage = percentage;
        _downloadSpeed = dlSpeed;
        _downloadTime = time;
        if (100 > percentage) {
          _message = 'Calculating $percentage% ...';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body = const Text('');

    if (null == _error && 0 == _downloadTime && 0 < _percentage) {
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 10),
          const SizedBox(height: 8.0),
          Text(_message),
        ],
      );
    } else if (_error?.isNotEmpty == true) {
      body = Text(
        _error ?? '',
        style: const TextStyle(
            color: Colors.red, fontSize: 16, fontWeight: FontWeight.w900),
      );
    } else if (0 < _downloadTime) {
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Running on: $_platformVersion\n'),
          Text('Download Speed: ${_downloadSpeed.toStringAsFixed(2)} Mbps\n'),
          Text('FW Revision: $_fwRevision\n'),
          Text('Flash file size: ${_fwDltimePlugin?.fwFileSize}\n'),
          Text(
              'Estimated download time: ${_downloadTime.toStringAsFixed(2)}s\n'),
        ],
      );
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FW Download Calculator'),
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: body),
              Container(
                decoration: kBodyContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onChanged: (value) {
                          _fwRevision = value;
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20.0),
                          hintText: _fwRevision,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 50,
                      focusColor: Colors.orange.withOpacity(0.3),
                      tooltip: 'Calculate',
                      icon: const Icon(Icons.network_check_rounded),
                      onPressed: () {
                        calculateDownloadTime(_fwRevision);
                        setState(() {
                          _message = 'Calculating ...';
                          _percentage = 1;
                          _downloadTime = 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _fwDltimePlugin?.getPlatformVersion() ??
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
}
