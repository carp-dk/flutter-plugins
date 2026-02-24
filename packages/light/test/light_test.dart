import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light/light.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Light.debugReset();
  });

  tearDown(() {
    Light.debugReset();
  });

  test('returns singleton instance', () {
    expect(identical(Light(), Light()), isTrue);
  });

  test('returns empty stream on unsupported platforms', () async {
    Light.debugIsAndroidOverride = false;
    Light.debugIsIOSOverride = false;
    expect(await Light().lightSensorStream.isEmpty, isTrue);
  });

  test('lightSensorStream parses numeric lux values', () async {
    final _FakeEventChannel fakeChannel =
        _FakeEventChannel('light.eventChannel')..install();
    addTearDown(fakeChannel.dispose);

    Light.debugIsAndroidOverride = true;
    Light.debugEventChannelOverride = EventChannel(fakeChannel.name);

    final Future<int> firstLux = Light().lightSensorStream.first;

    await _waitForListen(fakeChannel);
    fakeChannel.emitSuccess(123);

    expect(await firstLux, 123);
  });

  test('lightSensorStream maps invalid values to -1', () async {
    final _FakeEventChannel fakeChannel =
        _FakeEventChannel('light.eventChannel')..install();
    addTearDown(fakeChannel.dispose);

    Light.debugIsAndroidOverride = true;
    Light.debugEventChannelOverride = EventChannel(fakeChannel.name);

    final Future<int> firstLux = Light().lightSensorStream.first;

    await _waitForListen(fakeChannel);
    fakeChannel.emitSuccess('invalid');

    expect(await firstLux, -1);
  });

  test('lightSensorStream emits values on iOS', () async {
    final _FakeEventChannel fakeChannel =
        _FakeEventChannel('light.eventChannel')..install();
    addTearDown(fakeChannel.dispose);

    Light.debugIsAndroidOverride = false;
    Light.debugIsIOSOverride = true;
    Light.debugEventChannelOverride = EventChannel(fakeChannel.name);

    final Future<int> firstLux = Light().lightSensorStream.first;

    await _waitForListen(fakeChannel);
    fakeChannel.emitSuccess(350);

    expect(await firstLux, 350);
  });

  test('getAuthorizationStatus returns unavailable on non-iOS', () async {
    Light.debugIsIOSOverride = false;
    expect(await Light().getAuthorizationStatus(),
        LightAuthorizationStatus.unavailable);
  });

  test('getAuthorizationStatus parses native iOS status', () async {
    final _FakeMethodChannel fakeChannel = _FakeMethodChannel('light')
      ..install((MethodCall call) async {
        if (call.method == 'getAuthorizationStatus') {
          return 'authorized';
        }
        return null;
      });
    addTearDown(fakeChannel.dispose);

    Light.debugIsIOSOverride = true;
    Light.debugMethodChannelOverride = MethodChannel(fakeChannel.name);

    expect(await Light().getAuthorizationStatus(),
        LightAuthorizationStatus.authorized);
  });

  test('requestAuthorization falls back to current status when native throws',
      () async {
    final _FakeMethodChannel fakeChannel = _FakeMethodChannel('light')
      ..install((MethodCall call) async {
        if (call.method == 'requestAuthorization') {
          throw PlatformException(code: 'PERMISSION_DENIED');
        }
        if (call.method == 'getAuthorizationStatus') {
          return 'denied';
        }
        return null;
      });
    addTearDown(fakeChannel.dispose);

    Light.debugIsIOSOverride = true;
    Light.debugMethodChannelOverride = MethodChannel(fakeChannel.name);

    expect(await Light().requestAuthorization(),
        LightAuthorizationStatus.denied);
  });

  test('stream triggers listen and cancel on the platform channel', () async {
    final _FakeEventChannel fakeChannel =
        _FakeEventChannel('light.eventChannel')..install();
    addTearDown(fakeChannel.dispose);

    Light.debugIsAndroidOverride = true;
    Light.debugEventChannelOverride = EventChannel(fakeChannel.name);

    final StreamSubscription<int> subscription =
        Light().lightSensorStream.listen((_) {});
    await _waitForListen(fakeChannel);

    expect(fakeChannel.listenCalls, 1);

    await subscription.cancel();
    await _flushMicrotasks();

    expect(fakeChannel.cancelCalls, 1);
  });
}

Future<void> _waitForListen(_FakeEventChannel channel) async {
  for (int i = 0; i < 10; i++) {
    if (channel.listenCalls > 0) {
      return;
    }
    await _flushMicrotasks();
  }
  fail('Timed out waiting for ${channel.name} to receive listen.');
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeEventChannel {
  _FakeEventChannel(this.name)
      : _methodChannel = MethodChannel(name),
        _messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final String name;
  final MethodChannel _methodChannel;
  final TestDefaultBinaryMessenger _messenger;
  final StandardMethodCodec _codec = const StandardMethodCodec();

  int listenCalls = 0;
  int cancelCalls = 0;

  void install() {
    _messenger.setMockMethodCallHandler(_methodChannel,
        (MethodCall call) async {
      if (call.method == 'listen') {
        listenCalls++;
      } else if (call.method == 'cancel') {
        cancelCalls++;
      }
      return null;
    });
  }

  void dispose() {
    _messenger.setMockMethodCallHandler(_methodChannel, null);
  }

  void emitSuccess(dynamic event) {
    _messenger.handlePlatformMessage(
      name,
      _codec.encodeSuccessEnvelope(event),
      (_) {},
    );
  }
}

class _FakeMethodChannel {
  _FakeMethodChannel(this.name)
      : _methodChannel = MethodChannel(name),
        _messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final String name;
  final MethodChannel _methodChannel;
  final TestDefaultBinaryMessenger _messenger;

  void install(Future<dynamic> Function(MethodCall call) handler) {
    _messenger.setMockMethodCallHandler(_methodChannel, handler);
  }

  void dispose() {
    _messenger.setMockMethodCallHandler(_methodChannel, null);
  }
}
