import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:activity_recognition_flutter/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _configureChannel =
    'dev.flutter.pigeon.activity_recognition_flutter.ActivityRecognitionHostApi.configure';

final EventChannel _activityChannel = EventChannel(
  'dev.flutter.pigeon.activity_recognition_flutter.ActivityStreamApi.streamActivities',
  pigeonMethodCodec,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActivityEvent', () {
    test('exposes the activity type as a string', () {
      expect(ActivityEvent(ActivityType.WALKING, 75).typeString, 'WALKING');
    });

    test('unknown() reports an unknown activity', () {
      final event = ActivityEvent.unknown();

      expect(event.type, ActivityType.UNKNOWN);
      expect(event.confidence, 100);
    });

    test('falls back to the current time when none is given', () {
      final before = DateTime.now();
      final event = ActivityEvent(ActivityType.STILL, 50);

      expect(
        event.timeStamp.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );
    });

    test('describes itself', () {
      expect(
        ActivityEvent(ActivityType.RUNNING, 80).toString(),
        'Activity - type: RUNNING, confidence: 80%',
      );
    });
  });

  group('activityStream', () {
    late TestDefaultBinaryMessenger messenger;
    final List<TrackingConfiguration> configurations = <TrackingConfiguration>[];

    setUp(() {
      messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      messenger.setMockMessageHandler(
        _configureChannel,
        (ByteData? message) async {
          final args = ActivityRecognitionHostApi.pigeonChannelCodec
              .decodeMessage(message) as List<Object?>;
          configurations.add(args.first! as TrackingConfiguration);

          return ActivityRecognitionHostApi.pigeonChannelCodec
              .encodeMessage(<Object?>[null]);
        },
      );
    });

    tearDown(() {
      messenger.setMockMessageHandler(_configureChannel, null);
      messenger.setMockStreamHandler(_activityChannel, null);
    });

    test('configures the platform and maps detections to ActivityEvent',
        () async {
      messenger.setMockStreamHandler(
        _activityChannel,
        MockStreamHandler.inline(
          onListen: (Object? arguments, MockStreamHandlerEventSink events) {
            events.success(
              PlatformActivity(
                type: PlatformActivityType.onBicycle,
                confidence: 65,
                timestamp: 1700000000000,
              ),
            );
            events.endOfStream();
          },
        ),
      );

      final events = await ActivityRecognition()
          .activityStream(runForegroundService: false)
          .take(1)
          .toList();

      // The tracking options have to reach the platform before it starts.
      expect(configurations, hasLength(1));
      expect(configurations.single.runForegroundService, isFalse);

      expect(events, hasLength(1));
      expect(events.single.type, ActivityType.ON_BICYCLE);
      expect(events.single.confidence, 65);
      expect(
        events.single.timeStamp,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });
  });
}
