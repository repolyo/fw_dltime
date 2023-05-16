import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:speed_checker_plugin/speed_checker_plugin.dart';

import 'fw_dltime_platform_interface.dart';

typedef DownloadSpeed = void Function(double value, String? error);

class FwDltime {
  final bool debug;
  final SpeedCheckerPlugin plugin = SpeedCheckerPlugin();
  late StreamSubscription<SpeedTestResult> subscription;
  var currentSpeed = 0.0;
  var downloadSpeed = 0.0;
  var uploadSpeed = 0.0;

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
      final fSize = await getFirmwareFlashFileSize(fwRevision);
      if (0 == fSize) {
        callback.call(fSize.toDouble(), 'Unable to get file size: $fSize');
      }

      if (debug) {
        debugPrint('==================> Got file size: $fSize');
      }
      subscription = plugin.speedTestResultStream.listen(
        (result) async {
          currentSpeed = result.currentSpeed;
          downloadSpeed = result.downloadSpeed;
          uploadSpeed = result.uploadSpeed;
          const megaBytes = 1024 * 1024;
          final dwSpeedMBs = downloadSpeed * megaBytes;
          final info = await plugin.getIpInfo();

          if (debug) {
            final fwSizeMbs = (fSize / megaBytes).toStringAsFixed(2);
            debugPrint('==================> Internet info: $info');
            debugPrint('status: ${result.status}');
            debugPrint('ping: ${result.ping}');
            debugPrint('percent: ${result.percent}');
            debugPrint('currentSpeed: ${currentSpeed.toStringAsFixed(2)} Mbps');
            debugPrint('uploadSpeed: ${uploadSpeed.toStringAsFixed(2)} Mbps');

            debugPrint('==================> Model Name: $fwRevision');
            debugPrint('flash file size: $fwSizeMbs MB');
            debugPrint(
                'downloadSpeed: ${downloadSpeed.toStringAsFixed(2)} Mbps');
          }
          callback.call(fSize / dwSpeedMBs, null);

          dispose();
        },
        onDone: () {
          final dwSpeedMBs = downloadSpeed * 1024 * 1024;
          if (debug) {
            debugPrint('dwSpeedMBs: $dwSpeedMBs');
          }
          callback.call(fSize / dwSpeedMBs, null);

          dispose();
        },
        onError: (error) {
          callback.call(-0.0, error.toString());
          dispose();
        },
      );
    } catch (e) {
      callback.call(-0.0, e.toString());
      dispose();
    }
  }
}
