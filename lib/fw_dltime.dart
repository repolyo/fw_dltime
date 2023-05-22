import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:speed_checker_plugin/speed_checker_plugin.dart';

import 'fw_dltime_platform_interface.dart';

typedef FlashFileSizeCallback = void Function(int fwSize, {String? error});

typedef DownloadSpeedCallback = void Function(
    int percentage, double dlSpeed, double time, String? error);

class FwDltime {
  final megaBytes = 1024 * 1024;
  final bool debug;
  final SpeedCheckerPlugin _plugin = SpeedCheckerPlugin();
  StreamSubscription<SpeedTestResult>? _subscription;
  String fwRevision;
  int fwFileSize = 0;
  int calculationTime = 0;
  DateTime _startTime = DateTime.now();
  var currentBps = 0.0;
  var downloadBps = 0.0;
  var uploadBps = 0.0;

  FwDltime({required this.fwRevision, this.fwFileSize = 0, this.debug = false});

  void cancel() {
    _subscription?.cancel();
  }

  void dispose() {
    _subscription?.cancel();
    _plugin.dispose();
  }

  Future<int> getFirmwareFlashFileSize(
      FlashFileSizeCallback fileSizeCallback) async {
    try {
      final table = FirebaseFirestore.instance.collection('flash');
      final data = await table.doc(fwRevision).get();
      if (data.exists) {
        var flash = data.data();
        if (null != flash) {
          fwFileSize = flash['fwSize'] ?? 0;
        }
        fileSizeCallback.call(fwFileSize);
      } else {
        // try and see if we can find something similar
        final strFrontCode = fwRevision.substring(0, fwRevision.length - 1);
        final lastChar = fwRevision.characters.last;
        final strEndCode =
            strFrontCode + String.fromCharCode(lastChar.codeUnitAt(0) + 1);

        final records = await table
            .where('fwCode', isGreaterThanOrEqualTo: fwRevision)
            .where('fwCode', isLessThan: strEndCode)
            .get();

        debugPrint('found: ${records.docs.length}');
        if (records.docs.isEmpty) {
          fileSizeCallback.call(0, error: 'No record found: \'$fwRevision\'');
        } else {
          final doc = records.docs.firstOrNull;
          if (null == doc) {
            fileSizeCallback.call(0, error: 'No record found: \'$fwRevision\'');
          } else {
            fwFileSize = doc['fwSize'] ?? 0;
            fwRevision = doc['fwCode'] ?? fwRevision;

            if (debug) {
              debugPrint('=======================> Model: $fwRevision');
              debugPrint('=======================> Size: $fwFileSize');
            }
          }
        }
      }
    } catch (e) {
      fwFileSize = 0;
      fileSizeCallback.call(fwFileSize, error: e.toString());
    }

    return fwFileSize;
  }

  calculateDownloadTime(DownloadSpeedCallback callback,
      {FlashFileSizeCallback? fileSizeCallback}) async {
    _startTime = DateTime.now();
    _plugin.startSpeedTest();

    if (0 == fwFileSize) {
      fwFileSize = await getFirmwareFlashFileSize(fileSizeCallback ??
          (size, {error}) {
            if (null != error) {
              debugPrint('Error: $error');
              callback.call(100, downloadBps, 0, error);
              _subscription?.cancel();
            }
            if (debug) {
              debugPrint('flash file size: $size');
            }
          });

      // bail-out if we are unable to get the file size.
      if (0 == fwFileSize) return;
    }
    _subscription = _plugin.speedTestResultStream.listen(
      (result) async {
        final progress = result.percent - 1;
        currentBps = result.currentSpeed;
        downloadBps = result.downloadSpeed;
        uploadBps = result.uploadSpeed;

        final message =
            result.warning.isNotEmpty ? result.warning : result.error;

        if (debug) {
          debugPrint('status: ${result.status}');
          debugPrint('ping: ${result.ping}');
          debugPrint('percent: ${result.percent}');
        }

        if (0 < fwFileSize && downloadBps > 0) {
          final flashFileBytes = fwFileSize;
          final dwSpeedMBs = downloadBps * megaBytes;
          final calculatedTime = flashFileBytes / dwSpeedMBs;
          calculationTime =
              _diffBetweenTwoDatesInSeconds(_startTime, DateTime.now());

          if (debug) {
            final fwSizeMbs = (flashFileBytes / megaBytes).toStringAsFixed(2);
            debugPrint('currentSpeed: ${currentBps.toStringAsFixed(2)} Mbps');
            debugPrint('uploadSpeed: ${uploadBps.toStringAsFixed(2)} Mbps');
            debugPrint('download speed: ${downloadBps.toStringAsFixed(2)}s');

            debugPrint('==================> Model Name: $fwRevision');
            debugPrint('flash file size: $fwSizeMbs MB');

            debugPrint(
                'Calculated in about: ${calculationTime.toStringAsFixed(2)}s');
          }

          callback.call(progress, downloadBps, calculatedTime, message);
        } else {
          callback.call(progress, result.downloadSpeed, 0.0, message);
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

  int _diffBetweenTwoDatesInSeconds(
    final DateTime startDate,
    final DateTime endDate,
  ) {
    return endDate.difference(startDate).inSeconds;
  }
}
