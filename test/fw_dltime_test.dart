import 'package:flutter_test/flutter_test.dart';
import 'package:fw_dltime/fw_dltime.dart';
import 'package:fw_dltime/fw_dltime_method_channel.dart';
import 'package:fw_dltime/fw_dltime_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFwDltimePlatform
    with MockPlatformInterfaceMixin
    implements FwDltimePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<double> getDownloadTime({fwRevision = 'CSLBL.072.202'}) =>
      Future.value(10.0);
}

void main() {
  final FwDltimePlatform initialPlatform = FwDltimePlatform.instance;

  test('$MethodChannelFwDltime is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFwDltime>());
  });

  test('getPlatformVersion', () async {
    FwDltime fwDltimePlugin = FwDltime(fwRevision: '');
    MockFwDltimePlatform fakePlatform = MockFwDltimePlatform();
    FwDltimePlatform.instance = fakePlatform;

    expect(await fwDltimePlugin.getPlatformVersion(), '42');
  });
}
