import 'package:app_usage_example/main.dart' as app;
import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('app_usage.methodChannel');

  tearDown(() async {
    AppUsage.debugIsAndroidOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('loads usage information into the example app', (tester) async {
    AppUsage.debugIsAndroidOverride = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getUsage');

      final arguments = Map<String, dynamic>.from(call.arguments as Map);
      final start = arguments['start'] as int;
      final end = arguments['end'] as int;

      expect(start, lessThan(end));

      return <String, List<double>>{
        'com.example.mail': <double>[
          120,
          start / 1000,
          end / 1000,
          (end - const Duration(minutes: 5).inMilliseconds) / 1000,
        ],
      };
    });

    app.main();
    await tester.pumpAndSettle();

    expect(find.text('No usage data loaded yet.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('load_usage_button')));
    await tester.pumpAndSettle();

    expect(find.text('mail'), findsOneWidget);
    expect(find.text('com.example.mail'), findsOneWidget);
    expect(find.text('0:02:00.000000'), findsOneWidget);
  });

  testWidgets('shows channel errors in the example app', (tester) async {
    AppUsage.debugIsAndroidOverride = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'permission_denied',
        message: 'Usage access is not granted.',
      );
    });

    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('load_usage_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('usage_error_message')), findsOneWidget);
    expect(find.textContaining('permission_denied'), findsOneWidget);
  });
}
