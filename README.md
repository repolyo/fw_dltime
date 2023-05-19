# fw_dltime

Get approximate download time given a FW revision.
Calculation of the download time is done in a two step process:
1. Get the associated flash file size with the given FW revision.
2. Check and note the current mobile device network download speed.

Once we have this information, following formula is used to calculate the estimated download time:
```
Download time = file size / download speed
```

For example, let's say we want to download a file that is 100 MB in size and our internet connection speed is 10 Mbps.
Using the formula above, we can calculate the download time as follows:

```
Download time = 100 MB / 10 Mbps
Download time = 100,000,000 bytes / (10,000,000 bits/second)
Download time = 10 seconds
```

So, it will take approximately 10 seconds to download the 100 MB file with a 10 Mbps connection speed.

<img src="https://github.com/repolyo/fw_dltime/raw/main/output.png"/>

## Getting Started

To use this package, add fw_dltime as a dependency in your pubspec.yaml file.

## Usage

```dart
    final fwDlCalc = FwDltime(debug: true, fwRevision: _fwRevision);

    fwDlCalc.calculateDownloadTime(
      // optional callback to know the flash file size
      fileSizeCallback: (fwSize) {
        debugPrint('Flash file size: $fwSize');
      },
      // called multiple times with percentage from 0-100, 
      // after which estimated download time is given.
      (percentage, dlSpeed, time, error) {
        debugPrint('Percent: $percentage%');
        debugPrint('Download Speed: ${dlSpeed}Mbps');
        debugPrint('Estimated download time: ${time}s');
        if (null != error) {
          debugPrint('Error found: $error');
        }
      };
    ),
  );
```

