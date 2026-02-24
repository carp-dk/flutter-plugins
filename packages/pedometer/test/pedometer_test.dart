import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/pedometer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeEventChannel stepCountChannel;
  late _FakeEventChannel stepDetectionChannel;

  setUp(() {
    stepCountChannel = _FakeEventChannel('step_count')..install();
    stepDetectionChannel = _FakeEventChannel('step_detection')..install();
  });

  tearDown(() {
    stepCountChannel.dispose();
    stepDetectionChannel.dispose();
  });

  test('stepCountStream emits parsed steps with timestamp', () async {
    final DateTime before = DateTime.now();
    final Future<StepCount> firstEvent = Pedometer.stepCountStream.first;

    await _waitForListen(stepCountChannel);
    stepCountChannel.emitSuccess(123);

    final StepCount stepCount = await firstEvent;
    expect(stepCount.steps, 123);
    expect(
      stepCount.timeStamp.isAfter(before) ||
          stepCount.timeStamp.isAtSameMomentAs(before),
      isTrue,
    );
    expect(stepCount.toString(), contains('Steps taken: 123 at '));
  });

  test('stepCountStream forwards platform errors', () async {
    final Future<void> expectation = expectLater(
      Pedometer.stepCountStream,
      emitsError(
        isA<PlatformException>()
            .having((PlatformException e) => e.code, 'code', 'UNAVAILABLE')
            .having(
              (PlatformException e) => e.message,
              'message',
              'sensor unavailable',
            ),
      ),
    );

    await _waitForListen(stepCountChannel);
    stepCountChannel.emitError(
      code: 'UNAVAILABLE',
      message: 'sensor unavailable',
      details: 'No step counter sensor',
    );

    await expectation;
  });

  test('pedestrianStatusStream maps 1 to walking', () async {
    final Future<PedestrianStatus> firstEvent =
        Pedometer.pedestrianStatusStream.first;

    await _waitForListen(stepDetectionChannel);
    stepDetectionChannel.emitSuccess(1);

    final PedestrianStatus status = await firstEvent;
    expect(status.status, 'walking');
    expect(status.toString(), contains('Status: walking at '));
  });

  test('pedestrianStatusStream maps 0 to stopped', () async {
    final Future<PedestrianStatus> firstEvent =
        Pedometer.pedestrianStatusStream.first;

    await _waitForListen(stepDetectionChannel);
    stepDetectionChannel.emitSuccess(0);

    final PedestrianStatus status = await firstEvent;
    expect(status.status, 'stopped');
    expect(status.toString(), contains('Status: stopped at '));
  });

  test('pedestrianStatusStream forwards platform errors', () async {
    final Future<void> expectation = expectLater(
      Pedometer.pedestrianStatusStream,
      emitsError(
        isA<PlatformException>()
            .having(
              (PlatformException e) => e.code,
              'code',
              'PERMISSION_DENIED',
            )
            .having(
              (PlatformException e) => e.message,
              'message',
              'activity recognition denied',
            ),
      ),
    );

    await _waitForListen(stepDetectionChannel);
    stepDetectionChannel.emitError(
      code: 'PERMISSION_DENIED',
      message: 'activity recognition denied',
    );

    await expectation;
  });

  test('event streams trigger listen and cancel on the platform channel',
      () async {
    final StreamSubscription<StepCount> countSubscription =
        Pedometer.stepCountStream.listen((_) {});
    final StreamSubscription<PedestrianStatus> statusSubscription =
        Pedometer.pedestrianStatusStream.listen((_) {});

    await _waitForListen(stepCountChannel);
    await _waitForListen(stepDetectionChannel);
    expect(stepCountChannel.listenCalls, 1);
    expect(stepDetectionChannel.listenCalls, 1);

    await countSubscription.cancel();
    await statusSubscription.cancel();
    await _flushMicrotasks();

    expect(stepCountChannel.cancelCalls, 1);
    expect(stepDetectionChannel.cancelCalls, 1);
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
    _messenger.setMockMethodCallHandler(_methodChannel, (MethodCall call) async {
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

  void emitError({
    required String code,
    String? message,
    Object? details,
  }) {
    _messenger.handlePlatformMessage(
      name,
      _codec.encodeErrorEnvelope(
        code: code,
        message: message,
        details: details,
      ),
      (_) {},
    );
  }
}
