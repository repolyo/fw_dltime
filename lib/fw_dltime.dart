import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:speed_checker_plugin/speed_checker_plugin.dart';

import 'fw_dltime_platform_interface.dart';

typedef FlashFileSizeCallback = void Function(int fwSize);

typedef DownloadSpeedCallback = void Function(
    int percentage, double dlSpeed, double time, String? error);

class FwDltime {
  final megaBytes = 1024 * 1024;
  final bool debug;
  final String fwRevision;
  final SpeedCheckerPlugin plugin = SpeedCheckerPlugin();
  StreamSubscription<SpeedTestResult>? subscription;
  int fwFileSize = 0;
  var currentBps = 0.0;
  var downloadBps = 0.0;
  var uploadBps = 0.0;

  FwDltime({required this.fwRevision, this.debug = false});

  void dispose() {
    subscription?.cancel();
    plugin.dispose();
  }

  Future<int> getFirmwareFlashFileSize(
      FlashFileSizeCallback fileSizeCallback) async {
    final data = await FirebaseFirestore.instance
        .collection('flash')
        .doc(fwRevision)
        .get();
    if (data.exists) {
      var flash = data.data();
      if (null != flash) {
        fwFileSize = flash['fwSize'] ?? 0;
      }
    }

    fileSizeCallback.call(fwFileSize);
    return fwFileSize;
  }

  calculateDownloadTime(DownloadSpeedCallback callback,
      {FlashFileSizeCallback? fileSizeCallback}) async {
    plugin.startSpeedTest();

    if (0 == fwFileSize) {
      getFirmwareFlashFileSize(fileSizeCallback ??
          (size) {
            if (debug) {
              debugPrint('flash file size: $size');
            }
          });
    }
    subscription = plugin.speedTestResultStream.listen(
      (result) async {
        currentBps = result.currentSpeed;
        downloadBps = result.downloadSpeed;
        uploadBps = result.uploadSpeed;

        if (result.error.isNotEmpty == true) {
          callback.call(
              result.percent, result.downloadSpeed, 0.0, result.error);
        }

        if (debug) {
          debugPrint('status: ${result.status}');
          debugPrint('ping: ${result.ping}');
          debugPrint('percent: ${result.percent}');
        }

        if (0 < fwFileSize && downloadBps > 0) {
          final flashFileBytes = fwFileSize;
          final dwSpeedMBs = downloadBps * megaBytes;
          final calculatedTime = flashFileBytes / dwSpeedMBs;
          if (debug) {
            final fwSizeMbs = (flashFileBytes / megaBytes).toStringAsFixed(2);
            debugPrint('currentSpeed: ${currentBps.toStringAsFixed(2)} Mbps');
            debugPrint('uploadSpeed: ${uploadBps.toStringAsFixed(2)} Mbps');
            debugPrint('download speed: ${downloadBps.toStringAsFixed(2)}s');

            debugPrint('==================> Model Name: $fwRevision');
            debugPrint('flash file size: $fwSizeMbs MB');
          }

          callback.call(result.percent, downloadBps, calculatedTime, null);
        } else {
          callback.call(result.percent, result.downloadSpeed, 0.0, null);
        }
      },
      onDone: () {
        dispose();
      },
      onError: (error) {
        callback.call(100, 0.0, 0.0, error.toString());
        dispose();
      },
    );
  }

  Future<String?> getPlatformVersion() {
    return FwDltimePlatform.instance.getPlatformVersion();
  }

  //
  // Future<void> getDownloadTime({
  //   required DownloadSpeedCallback callback,
  //   fwRevision = 'CSLBL.072.202',
  // }) async {
  //   _callback = callback;
  //   _fwRevision = fwRevision;
  //   try {
  //     _flashFileBytes = await getFirmwareFlashFileSize(fwRevision);
  //     if (0 == _flashFileBytes) {
  //       callback.call(0.0, 0, _flashFileBytes!.toDouble(),
  //           'Unable to get file size: $_flashFileBytes');
  //       dispose();
  //     }
  //
  //     if (debug) {
  //       debugPrint('==================> Got file size: $_flashFileBytes');
  //     }
  //   } catch (e) {
  //     _callback?.call(0.0, 0, 0.0, e.toString());
  //     dispose();
  //   }
  // }
}
