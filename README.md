# fw_dltime

Get approximate download time given a FW revision.

## Getting Started

To use this package, add fw_dltime as a dependency in your pubspec.yaml file.

## Usage

```dart
    class _MyAppState extends State<MyApp> {
      final _plugin = FwDltime(debug: true);
      late double _fwFileSizeBytes;
      late double _dlSpeedBps;
      late double _dlTimeSecond;

      @override
      void initState() {
        super.initState();
        const megaBytes = 1024 * 1024;

        _plugin.getDownloadTime(
          fwRevision: 'CSLBL.072.202',
          callback: (double dlSpeed, int fwSize, double time, String? error) {
            if (null != error) {
              debugPrint('=======> error: $error');
            }
            debugPrint('=======> Estimated download time: $time');

            setState(() {
              _dlSpeedBps = dlSpeed;
              _fwFileSizeBytes = fwSize;
              _dlTimeSecond = time;
            });
          },
        );
      }

      @override
      void dispose() {
        _plugin.dispose();
        super.dispose();
      }

      @override
      Widget build(BuildContext context) {

        return MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('FW estimated download time'),
            ),
            body: Center(
              child: Column(
                children: [
                  Text(
                      'Download Speed: ${_dlSpeedBps.toStringAsFixed(2)} Mbps\n'),
                  Text('FW Revision: $_fwRevision\n'),
                  Text('Flash file size: $_fwFileSizeBytes\n'),
                  Text(
                      'Estimated download time: ${_dlTimeSecond.toStringAsFixed(2)}s\n'),
                ],
              ),
            ),
          ),
        );
      }
   }
```

