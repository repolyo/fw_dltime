import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:speed_checker_plugin/speed_checker_plugin.dart';

import 'fw_dltime_platform_interface.dart';

typedef DownloadSpeed = void Function(
    double dlSpeed, int fwSize, double time, String? error);

class FwDltime {
  final bool debug;
  final SpeedCheckerPlugin plugin = SpeedCheckerPlugin();
  late StreamSubscription<SpeedTestResult> subscription;
  var currentBps = 0.0;
  var downloadBps = 0.0;
  var uploadBps = 0.0;

  FwDltime({this.debug = false}) {
    plugin.startSpeedTest();
  }

  void dispose() {
    subscription.cancel();
    plugin.dispose();
  }

  Future<String?> getPlatformVersion() {
    return FwDltimePlatform.instance.getPlatformVersion();
  }

  Future<int> getFirmwareFlashFileSize(fwRevision) async {
    var fwSize = 0;
    final data = await FirebaseFirestore.instance
        .collection('flash')
        .doc(fwRevision)
        .get();
    if (data.exists) {
      var flash = data.data();
      if (null != flash) {
        fwSize = flash['fwSize'] ?? 0;
      }
    }
    return fwSize;
  }

  Future<void> getDownloadTime({
    required DownloadSpeed callback,
    fwRevision = 'CSLBL.072.202',
  }) async {
    try {
      const megaBytes = 1024 * 1024;
      final flashFileBytes = await getFirmwareFlashFileSize(fwRevision);
      if (0 == flashFileBytes) {
        callback.call(0.0, 0, flashFileBytes.toDouble(),
            'Unable to get file size: $flashFileBytes');
      }

      if (debug) {
        debugPrint('==================> Got file size: $flashFileBytes');
      }
      subscription = plugin.speedTestResultStream.listen(
        (result) async {
          currentBps = result.currentSpeed;
          downloadBps = result.downloadSpeed;
          uploadBps = result.uploadSpeed;

          final dwSpeedMBs = downloadBps * megaBytes;
          final info = await plugin.getIpInfo();

          if (debug) {
            final fwSizeMbs = (flashFileBytes / megaBytes).toStringAsFixed(2);
            debugPrint('==================> Internet info: $info');
            debugPrint('status: ${result.status}');
            debugPrint('ping: ${result.ping}');
            debugPrint('percent: ${result.percent}');
            debugPrint('currentSpeed: ${currentBps.toStringAsFixed(2)} Mbps');
            debugPrint('uploadSpeed: ${uploadBps.toStringAsFixed(2)} Mbps');
            debugPrint(
                'download speed: ${downloadBps.toStringAsFixed(2)} Mbps');

            debugPrint('==================> Model Name: $fwRevision');
            debugPrint('flash file size: $fwSizeMbs MB');
          }
          callback.call(
              downloadBps, flashFileBytes, flashFileBytes / dwSpeedMBs, null);

          dispose();
        },
        onDone: () {
          final dwSpeedMBs = downloadBps * megaBytes;
          if (debug) {
            debugPrint('dwSpeedMBs: $dwSpeedMBs');
          }
          callback.call(
              dwSpeedMBs, flashFileBytes, flashFileBytes / dwSpeedMBs, null);

          dispose();
        },
        onError: (error) {
          callback.call(0.0, 0, 0.0, error.toString());
          dispose();
        },
      );
    } catch (e) {
      callback.call(0.0, 0, 0.0, e.toString());
      dispose();
    }
  }
}
