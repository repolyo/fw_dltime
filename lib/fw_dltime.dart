library fw_dltime;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:speed_test_dart/classes/server.dart';
import 'package:speed_test_dart/speed_test_dart.dart';

typedef FlashFileSizeCallback = void Function(int fwSize, {String? error});

typedef DownloadSpeedCallback = void Function(
    int percentage, double dlSpeed, double time, String? error);

class FwDltime {
  final megaBytes = 1024 * 1024;
  final bool debug;
  String fwRevision;
  int fwFileSize = 0;
  int calculationTime = 0;
  var currentBps = 0.0;
  var downloadBps = 0.0;
  var uploadBps = 0.0;

  FwDltime(
      {this.fwRevision = 'CSLBL.081', this.fwFileSize = 0, this.debug = false});

  void cancel() {
    if (debug) {
      debugPrint('FwDltime -- cancel()');
    }
  }

  void dispose() {
    if (debug) {
      debugPrint('FwDltime -- dispose()');
    }
  }

  _setDefault(CollectionReference table) {
    // insert not found FW revision to our DB so we would know which
    // FW revision needs data and be populated later on...
    table.doc(fwRevision).set({'fwCode': fwRevision, 'fwSize': 0});

    // provide the maximum FW size for client to have valid estimated
    // download time. => 680MB
    fwFileSize = 713031680;
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
        if (0 < fwFileSize) {
          fileSizeCallback.call(fwFileSize);
        } else {
          fileSizeCallback.call(0, error: 'No record found: \'$fwRevision\'');
        }
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
          if (debug) {
            debugPrint('No record found: \'$fwRevision\'');
          }
          _setDefault(table);
        } else {
          final doc = records.docs.firstOrNull;
          if (null == doc) {
            debugPrint('No record found: \'$fwRevision\'');
            _setDefault(table);
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
    if (0 == fwFileSize) {
      fwFileSize = await getFirmwareFlashFileSize(fileSizeCallback ??
          (size, {error}) {
            if (null != error) {
              debugPrint('Error: $error');
              callback.call(100, downloadBps, 0, error);
            }
            if (debug) {
              debugPrint('flash file size: $size');
            }
          });

      // bail-out if we are unable to get the file size.
      if (0 == fwFileSize) return;
    }

    final SpeedTestDart plugin = SpeedTestDart();
    final settings = await plugin.getSettings();
    final List<Server> bestServersList = await plugin.getBestServers(
      servers: settings.servers,
    );

    // Test download speed in MB/s
    double downloadMps =
        await plugin.testDownloadSpeed(servers: bestServersList);

    downloadBps = downloadMps * megaBytes;
    final calculatedTime = fwFileSize / downloadBps;
    callback.call(100, downloadMps, calculatedTime, null);
  }
}
