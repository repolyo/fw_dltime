# fw_dltime

Get approximate download time given a FW revision.

## Getting Started

To use this package, add fw_dltime as a dependency in your pubspec.yaml file.

## Usage

```dart
    class _MyAppState extends State<MyApp> {
      final _plugin = FwDltime(debug: true);
      late double _downloadTime;

      @override
      void initState() {
        super.initState();

        _plugin.getDownloadTime(
          fwRevision: 'CSLBL.072.202',
          callback: (double downloadTime, String? error) {
            debugPrint('=======> error: $error');
            debugPrint('=======> downloadSpeed: $downloadSpeed');

            setState(() {
                _downloadTime = downloadTime;
            });
          },
        );
      }

      @override
      void dispose() {
        _plugin.dispose();
        super.dispose();
      }

   }
```

