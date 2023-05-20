# fw_dltime

Get approximate download time given a target file size for download.
Calculation of the download time is done with the following information:
1. File size, size of the file we want to download, typically measured in bytes, kilobytes (KB), megabytes (MB), or gigabytes (GB).
2. Check and note the current mobile device network download speed.

Once we have these two information, following formula is used to calculate the estimated download time:
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

<p float="left">
<img src="https://github.com/repolyo/fw_dltime/raw/main/fw_dltime.png" width=300/>
<img src="https://github.com/repolyo/fw_dltime/raw/main/fw_dltime_android.png" width=300
</p>

## Getting Started

To use this package, add fw_dltime as a dependency in your pubspec.yaml file.

## Usage

```dart
    final fwDlCalc = FwDltime(debug: true, fwFileSize: 66162476);

    fwDlCalc.calculateDownloadTime(
      // called multiple times with percentage from 0-100, 
      // after which estimated download time is given.
      (percentage, dlSpeed, time, error) {
        if (null != error) {
          debugPrint('Error found: $error');
        }
        else if (100 == percent) {
            debugPrint('File size: ${fwDlCalc.fwFileSize} bytes');
            debugPrint('Download Speed: ${dlSpeed}Mbps');
            debugPrint('Estimated download time: ${time}s');
        } else {
          debugPrint('Calculation progress: $percentage%');
        }
      };
    ),
  );
```

