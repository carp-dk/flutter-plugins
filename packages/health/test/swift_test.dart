import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:mockito/mockito.dart';

import 'mocks/device_info_mock.dart';

// Mock MethodChannel to simulate native responses
class MockMethodChannel extends Mock implements MethodChannel {
  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    if (method == 'getData') {
      final dataTypeKey = (arguments as Map)['dataTypeKey'];
      switch (dataTypeKey) {
        case 'HEART_RATE':
          return Future.value(<Map<String, dynamic>>[
            {
              'uuid': 'test-uuid-1',
              'value': 75.5,
              'date_from': DateTime(2024, 9, 24, 12, 0).millisecondsSinceEpoch,
              'date_to': DateTime(2024, 9, 24, 12, 0).millisecondsSinceEpoch,
              'source_id': 'com.apple.Health',
              'source_name': 'Health',
              'recording_method': 2, // automatic
              'metadata': {
                'HKDeviceName': 'Apple Watch',
                'HKExternalUUID': '123e4567-e89b-12d3-a456-426614174000',
                'recording_method': 2,
              }
            }
          ] as T);
        case 'WORKOUT':
          return Future.value(<Map<String, dynamic>>[
            {
              'uuid': 'test-uuid-2',
              'workoutActivityType': 'RUNNING',
              'totalEnergyBurned': 200.0,
              'totalEnergyBurnedUnit': 'KILOCALORIE',
              'totalDistance': 5000.0,
              'totalDistanceUnit': 'METER',
              'date_from': DateTime(2024, 9, 24, 12, 0).millisecondsSinceEpoch,
              'date_to': DateTime(2024, 9, 24, 13, 0).millisecondsSinceEpoch,
              'source_id': 'com.apple.Health',
              'source_name': 'Health',
              'recording_method': 2,
              'metadata': {
                'HKDeviceName': 'Apple Watch',
                'complex': {
                  'key': 'value',
                  'number': 42,
                },
              }
            }
          ] as T);
        case 'NUTRITION':
          return Future.value(<Map<String, dynamic>>[
            {
              'uuid': 'test-uuid-3',
              'name': 'Lunch',
              'meal_type': 'LUNCH',
              'calories': 500.0,
              'carbs': 60.0,
              'protein': 20.0,
              'date_from': DateTime(2024, 9, 24, 13, 0).millisecondsSinceEpoch,
              'date_to': DateTime(2024, 9, 24, 13, 30).millisecondsSinceEpoch,
              'source_id': 'com.apple.Health',
              'source_name': 'Health',
              'recording_method': 2,
              'metadata': {
                'HKFoodMeal': 'LUNCH',
                'array': [1, 'test', false, 'DateTime.now()'],
              }
            }
          ] as T);
        default:
          return Future.value(<Map<String, dynamic>>[] as T);
      }
    }
    return Future.value(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Define the channel
  const channel = MethodChannel('flutter_health');
  final mockChannel = MockMethodChannel();

  setUp(() {
    // Use the updated method to set the mock handler
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) => mockChannel.invokeMethod(call.method, call.arguments));
  });

  tearDown(() {
    // Clear the mock handler
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Sanitization via getHealthDataFromTypes', () {
    final health = Health(deviceInfo: MockDeviceInfoPlugin());

    setUpAll(() async {
      await health.configure();
    });

    test('Test sanitization with simple metadata - HEART_RATE', () async {
      final dataPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: DateTime(2024, 9, 24, 0, 0),
        endTime: DateTime(2024, 9, 24, 23, 59),
      );

      expect(dataPoints.length, 1);
      final hdp = dataPoints.first;
      expect(hdp.type, HealthDataType.HEART_RATE);
      expect(hdp.metadata, {
        'HKDeviceName': 'Apple Watch',
        'HKExternalUUID': '123e4567-e89b-12d3-a456-426614174000',
        'recording_method': 2,
      });
      expect(hdp.value, isA<NumericHealthValue>());
      expect((hdp.value as NumericHealthValue).numericValue, 75.5);
    });

    test('Test sanitization with nested metadata - WORKOUT', () async {
      final dataPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: DateTime(2024, 9, 24, 0, 0),
        endTime: DateTime(2024, 9, 24, 23, 59),
      );

      expect(dataPoints.length, 1);
      final hdp = dataPoints.first;
      expect(hdp.type, HealthDataType.WORKOUT);
      expect(hdp.metadata, {
        'HKDeviceName': 'Apple Watch',
        'complex': {
          'key': 'value',
          'number': 42,
        },
        // 'unsupported' should be filtered out
      });
      expect(hdp.value, isA<WorkoutHealthValue>());
      final workoutValue = hdp.value as WorkoutHealthValue;
      expect(workoutValue.workoutActivityType, HealthWorkoutActivityType.RUNNING);
      expect(workoutValue.totalEnergyBurned, 200);
      expect(workoutValue.totalDistance, 5000);
    });

    test('Test sanitization with array in metadata - NUTRITION', () async {
      final dataPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.NUTRITION],
        startTime: DateTime(2024, 9, 24, 0, 0),
        endTime: DateTime(2024, 9, 24, 23, 59),
      );

      expect(dataPoints.length, 1);
      final hdp = dataPoints.first;
      expect(hdp.type, HealthDataType.NUTRITION);
      expect(hdp.metadata, {
        'HKFoodMeal': 'LUNCH',
        'array': [1, 'test', false, 'DateTime.now()'], // 'DateTime.now()' should be filtered out
      });
      expect(hdp.value, isA<NutritionHealthValue>());
      final nutritionValue = hdp.value as NutritionHealthValue;
      expect(nutritionValue.calories, 500.0);
      expect(nutritionValue.carbs, 60.0);
      expect(nutritionValue.protein, 20.0);
    });
  });
}