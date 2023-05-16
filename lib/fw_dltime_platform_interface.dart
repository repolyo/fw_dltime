import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'fw_dltime_method_channel.dart';

abstract class FwDltimePlatform extends PlatformInterface {
  /// Constructs a FwDltimePlatform.
  FwDltimePlatform() : super(token: _token);

  static final Object _token = Object();

  static FwDltimePlatform _instance = MethodChannelFwDltime();

  /// The default instance of [FwDltimePlatform] to use.
  ///
  /// Defaults to [MethodChannelFwDltime].
  static FwDltimePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FwDltimePlatform] when
  /// they register themselves.
  static set instance(FwDltimePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<double> getDownloadTime({
    fwRevision = 'CSLBL.072.202',
  }) {
    throw UnimplementedError('getDownloadTime() has not been implemented.');
  }
}
