import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fw_dltime_platform_interface.dart';

/// An implementation of [FwDltimePlatform] that uses method channels.
class MethodChannelFwDltime extends FwDltimePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('fw_dltime');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
