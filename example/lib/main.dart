import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  late AnimationController _animationController;
  late Animation _animation;
  String _fwRevision = 'CSLBL.081';
  FwDltime? _fwDltimePlugin;
  String? _error;
  double _downloadTime = 0.0;
  double _downloadSpeed = 0.0;
  String _message = '';
  int _percentage = 0;
  int _index = 0;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));

    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    super.initState();

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse(from: 1.0);
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    _animationController.addListener(() {
      double doubleValue = _animation.value * 5;
      int intVaue = doubleValue.toInt();
      if (intVaue == _index) return; // refresh screen only if necessary!

      setState(() {
        _index = intVaue;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fwDltimePlugin?.dispose();
    super.dispose();
  }

  calculateDownloadTime(fwRevision) async {
    String platformVersion;
    _fwDltimePlugin?.dispose();
    _fwRevision = fwRevision;
    _fwDltimePlugin = FwDltime(debug: false, fwRevision: _fwRevision);

    _fwDltimePlugin?.calculateDownloadTime((percentage, dlSpeed, time, error) {
      if (!mounted || 0 == percentage) return;

      setState(() {
        _error = error;
        _percentage = percentage;
        _downloadSpeed = dlSpeed;
        _downloadTime = time;
        _message = '';
        if (0 < percentage && percentage < 100) {
          _message = 'Calculating $percentage% ...';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body = const Text('');

    if (0 < _downloadTime) {
      _animationController.stop();
      _fwDltimePlugin?.cancel();

      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Download Speed: ${_downloadSpeed.toStringAsFixed(2)} Mbps'),
          Text('FW Revision: ${_fwDltimePlugin?.fwRevision ?? _fwRevision}'),
          Text('Flash file size: ${_fwDltimePlugin?.fwFileSize} bytes'),
          Text('Estimated download time: ${_downloadTime.toStringAsFixed(2)}s'),
        ],
      );
    } else {
      if (100 == _percentage) {
        // were done
        _animationController.stop();
      }

      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (0 < _percentage && 100 > _percentage)
            const CircularProgressIndicator(strokeWidth: 10),
          const SizedBox(height: 8.0),
          Text(_message),
          Text(
            _error ?? '',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      );
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Download Time Calculator'),
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
                      icon: _animationController.isAnimating
                          ? Image.asset('images/wifi_$_index.png')
                          : const Icon(Icons.network_check),
                      onPressed: () {
                        _animationController.forward();
                        calculateDownloadTime(_fwRevision);
                        setState(() {
                          _error = null;
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

  noError() => 0 < _percentage && 100 > _percentage;
}
