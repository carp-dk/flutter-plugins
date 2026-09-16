library mobility_test;

import 'dart:async';
import 'package:mobility_features/mobility_features.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:carp_serializable/carp_serializable.dart';

part 'test_utils.dart';

void main() async {
  DateTime jan01 = DateTime(2020, 01, 01);

  // Poppelgade 7, home
  GeoLocation pos1 = GeoLocation(55.692035, 12.558575);

  // Falkoner Alle
  GeoLocation pos2 = GeoLocation(55.685329, 12.538601);

  // Dronning Louises Bro
  // ignore: unused_local_variable
  GeoLocation pos3 = GeoLocation(55.686723, 12.563769);

  // Assistentens Kirkegaard
  // ignore: unused_local_variable
  GeoLocation pos4 = GeoLocation(55.690862, 12.549545);

  /// This test  verifies that the 'midnight' extension
  /// works for two DateTime objects on the same date.
  test('Datetime extension', () async {
    DateTime d1 = DateTime.parse('2020-02-12 09:30:00.000');
    DateTime d2 = DateTime.parse('2020-02-12 13:31:00.400');
    expect(d1.midnight, d2.midnight);

    DateTime d3 = DateTime.parse('2020-02-13 09:30:00.000');
    expect(d1.midnight, isNot(d3.midnight));
  });

  group("Mobility Context Tests", () {
    test('Serialize and load three location samples', () async {
      LocationSample x =
          LocationSample(GeoLocation(123.456, 123.456), DateTime(2020, 01, 01));

      List<LocationSample> dataset = [x, x, x];

      flushFiles();

      await MobilityFeatures().saveSamples(dataset);

      List<LocationSample> loaded = await MobilityFeatures().loadSamples();
      printList(loaded);
      expect(loaded.length, dataset.length);
    });

    test('Serialize and load and multiple days', () async {
      flushFiles();

      List<LocationSample> dataset = [];

      for (int i = 0; i < 5; i++) {
        DateTime date = jan01.add(Duration(days: i));

        /// Todays data
        List<LocationSample> locationSamples = [
          // 5 hours spent at home
          LocationSample(pos1, date.add(const Duration(hours: 0, minutes: 0))),
          LocationSample(pos1, date.add(const Duration(hours: 6, minutes: 0))),

          LocationSample(pos2, date.add(const Duration(hours: 8, minutes: 0))),
          LocationSample(pos2, date.add(const Duration(hours: 9, minutes: 30))),
        ];

        /// Save
        await MobilityFeatures().saveSamples(locationSamples);
        dataset.addAll(locationSamples);

        /// Load, make sure data from previous days is not stored.
        List<LocationSample> loaded = await MobilityFeatures().loadSamples();
        expect(loaded.length, dataset.length);
      }
    });

    test('Test that samples persist', () async {
      // Clean file every time test is run
      flushFiles();

      List<LocationSample> samples = [
        // 5 hours spent at home
        LocationSample(pos1, jan01.add(const Duration(hours: 0, minutes: 0))),
        LocationSample(pos1, jan01.add(const Duration(hours: 6, minutes: 0))),

        LocationSample(pos2, jan01.add(const Duration(hours: 8, minutes: 0))),
        LocationSample(pos2, jan01.add(const Duration(hours: 9, minutes: 0))),

        LocationSample(pos1, jan01.add(const Duration(hours: 21, minutes: 0))),
        LocationSample(pos1,
            jan01.add(const Duration(hours: 23, minutes: 59, seconds: 59))),
      ];

      await MobilityFeatures().saveSamples(samples);
      final loaded = await MobilityFeatures().loadSamples();
      expect(loaded.length, samples.length);
    });

    test('Remove duplicate samples', () async {
      // Clean file every time test is run
      flushFiles();

      List<LocationSample> samplesNoDuplicates = [
        // 5 hours spent at home
        LocationSample(pos1, jan01.add(const Duration(hours: 0, minutes: 0))),
        LocationSample(pos1, jan01.add(const Duration(hours: 6, minutes: 0))),

        LocationSample(pos2, jan01.add(const Duration(hours: 8, minutes: 0))),
        LocationSample(pos2, jan01.add(const Duration(hours: 9, minutes: 0))),

        LocationSample(pos1, jan01.add(const Duration(hours: 21, minutes: 0))),
        LocationSample(pos1,
            jan01.add(const Duration(hours: 23, minutes: 59, seconds: 59))),
      ];

      /// Todays data
      List<LocationSample> samplesWithDuplicates = [
        // 5 hours spent at home
        LocationSample(pos1, jan01.add(const Duration(hours: 0, minutes: 0))),
        LocationSample(pos1, jan01.add(const Duration(hours: 6, minutes: 0))),
        LocationSample(pos1, jan01.add(const Duration(hours: 6, minutes: 0))),
        LocationSample(pos1, jan01.add(const Duration(hours: 6, minutes: 0))),

        LocationSample(pos2, jan01.add(const Duration(hours: 8, minutes: 0))),
        LocationSample(pos2, jan01.add(const Duration(hours: 8, minutes: 0))),
        LocationSample(pos2, jan01.add(const Duration(hours: 8, minutes: 0))),
        LocationSample(pos2, jan01.add(const Duration(hours: 9, minutes: 0))),

        LocationSample(pos1, jan01.add(const Duration(hours: 0, minutes: 0))),
        LocationSample(pos1, jan01.add(const Duration(hours: 6, minutes: 0))),
        LocationSample(pos1, jan01.add(const Duration(hours: 6, minutes: 0))),
        LocationSample(pos1, jan01.add(const Duration(hours: 6, minutes: 0))),

        LocationSample(pos1, jan01.add(const Duration(hours: 21, minutes: 0))),
        LocationSample(pos1,
            jan01.add(const Duration(hours: 23, minutes: 59, seconds: 59))),
      ];

      final samples = MobilityFeatures.uniqueElements(samplesWithDuplicates);
      expect(samples.length, samplesNoDuplicates.length);
    });

    test('Save samples one at a time', () async {
      flushFiles();

      List<LocationSample> samples = [
        /// Location 1
        LocationSample(pos1, jan01.add(const Duration(hours: 0, minutes: 0))),
        LocationSample(pos1, jan01.add(const Duration(hours: 6, minutes: 0))),

        /// Location 2
        LocationSample(pos2, jan01.add(const Duration(hours: 8, minutes: 0))),
        LocationSample(pos2, jan01.add(const Duration(hours: 9, minutes: 0))),

        /// Location 1
        LocationSample(pos1, jan01.add(const Duration(hours: 21, minutes: 0))),
        LocationSample(pos1,
            jan01.add(const Duration(hours: 23, minutes: 59, seconds: 59))),
      ];

      // Save samples, one by one
      for (var s in samples) {
        MobilityFeatures().saveSamples([s]);
      }

      // Load samples again, verify that they were all saved
      final loaded = await MobilityFeatures().loadSamples();
      expect(samples.length, loaded.length);
    });

    test('Stream Location Samples', () async {
      flushFiles();
      DateTime date = jan01;

      List<LocationSample> samples = [
        /// Location 1 (Home)
        LocationSample(pos1, date.add(const Duration(hours: 0, minutes: 0))),
        LocationSample(pos1, date.add(const Duration(hours: 1, minutes: 0))),
        LocationSample(pos1, date.add(const Duration(hours: 2, minutes: 0))),
        LocationSample(pos1, date.add(const Duration(hours: 8, minutes: 0))),

        /// end of stop 1

        /// Location 2
        LocationSample(pos2, date.add(const Duration(hours: 8, minutes: 30))),
        LocationSample(pos2, date.add(const Duration(hours: 9, minutes: 30))),
        LocationSample(pos2, date.add(const Duration(hours: 12, minutes: 30))),

        /// end of stop 2

        /// Gap in data

        // Location 1 (Home)
        LocationSample(pos1, date.add(const Duration(hours: 16, seconds: 1))),
        LocationSample(pos1, date.add(const Duration(hours: 20, minutes: 0))),

        /// end of stop 3

        // Location 0 (Home), New day
        LocationSample(
            pos1, date.add(const Duration(days: 1, hours: 0, minutes: 2))),
      ];

      // Create stream controller to stream the individual samples
      // to the MobilityFactory instance
      StreamController<LocationSample> controller =
          StreamController.broadcast();

      // Set up stream
      await MobilityFeatures().startListening(controller.stream);

      int expectedContexts = 3;

      // Listen to the Context stream
      Stream<MobilityContext> contextStream = MobilityFeatures().contextStream;
      contextStream.listen(expectAsync1((c) {
        printList(c.stops!);
        print(toJsonString(c.toJson()));
      }, count: expectedContexts));

      // Stream all the samples one by one
      for (LocationSample s in samples) {
        controller.add(s);
      }
      controller.close();
    });

    test('Stream LocationSamples with path between locations', () async {
      void onContext(MobilityContext mc) {
        print(mc.toJson());
        printList(mc.stops!);
        // Once there is a move, distance is the walked path (~1.5 km home ->
        // Falkoner Alle), not 0 - the path window must span the two stops.
        if (mc.numberOfMoves! > 0) {
          expect(mc.distanceTraveled, greaterThan(1000));
        }
      }

      flushFiles();
      DateTime date = jan01;

      List<LocationSample> samples = [
        /// Location 1 (Home)
        LocationSample(pos1, date.add(const Duration(hours: 0, minutes: 0))),
        LocationSample(pos1, date.add(const Duration(hours: 1, minutes: 0))),
        LocationSample(pos1, date.add(const Duration(hours: 2, minutes: 0))),
        LocationSample(pos1, date.add(const Duration(hours: 8, minutes: 0))),

        /// end of stop 1

        /// Path to Location 1
        LocationSample(GeoLocation(55.691806, 12.557528),
            date.add(const Duration(hours: 8, minutes: 1))),
        LocationSample(GeoLocation(55.691419, 12.556970),
            date.add(const Duration(hours: 8, minutes: 2))),
        LocationSample(GeoLocation(55.691081, 12.556455),
            date.add(const Duration(hours: 8, minutes: 3))),
        LocationSample(GeoLocation(55.690706, 12.555875),
            date.add(const Duration(hours: 8, minutes: 4))),
        LocationSample(GeoLocation(55.690434, 12.555457),
            date.add(const Duration(hours: 8, minutes: 5))),
        LocationSample(GeoLocation(55.690161, 12.555060),
            date.add(const Duration(hours: 8, minutes: 6))),
        LocationSample(GeoLocation(55.690542, 12.554481),
            date.add(const Duration(hours: 8, minutes: 7))),
        LocationSample(GeoLocation(55.690801, 12.550164),
            date.add(const Duration(hours: 8, minutes: 8))),
        LocationSample(GeoLocation(55.690825, 12.544910),
            date.add(const Duration(hours: 8, minutes: 9))),
        LocationSample(GeoLocation(55.689685, 12.543661),
            date.add(const Duration(hours: 8, minutes: 15))),
        LocationSample(GeoLocation(55.688083, 12.541852),
            date.add(const Duration(hours: 8, minutes: 20))),
        LocationSample(GeoLocation(55.686007, 12.539484),
            date.add(const Duration(hours: 8, minutes: 29))),

        /// Location 1
        LocationSample(pos2, date.add(const Duration(hours: 8, minutes: 30))),
        LocationSample(pos2, date.add(const Duration(hours: 10, minutes: 30))),
        LocationSample(pos2, date.add(const Duration(hours: 11, minutes: 30))),
        LocationSample(pos2, date.add(const Duration(hours: 12, minutes: 30))),

        /// end of stop 2

        /// Gap in data from 12:30 to 16:00

        /// Location 0 (Home)
        LocationSample(pos1, date.add(const Duration(hours: 16, seconds: 1))),
        LocationSample(pos1, date.add(const Duration(hours: 20, minutes: 0))),

        /// end of stop 3

        /// Location 0 (Home), New day
        LocationSample(
            pos1, date.add(const Duration(days: 1, hours: 0, minutes: 2))),
      ];

      /// Create stream controller to stream the individual samples
      /// to the MobilityFactory instance
      StreamController<LocationSample> controller =
          StreamController.broadcast();

      // Set up stream
      await MobilityFeatures().startListening(controller.stream);

      int expectedContexts = 3;

      /// Listen to the Context stream
      Stream<MobilityContext> contextStream = MobilityFeatures().contextStream;
      contextStream.listen(expectAsync1(onContext, count: expectedContexts));

      // Stream all the samples one by one
      for (LocationSample s in samples) {
        controller.add(s);
      }
      controller.close();
    });

    test('Stream with noise on data points (stop merging)', () async {
      flushFiles();
      DateTime date = jan01;

      List<LocationSample> samples = [
        /// Location 1 (Home)
        LocationSample(pos1, date.add(const Duration(hours: 0, minutes: 0))),
        LocationSample(pos1, date.add(const Duration(hours: 1, minutes: 0))),

        /// end of stop 1
        LocationSample(pos1, date.add(const Duration(hours: 2, minutes: 0)))
            .addNoise(),
        LocationSample(pos1, date.add(const Duration(hours: 8, minutes: 0)))
            .addNoise(),

        /// end of stop 2

        /// Location 1
        LocationSample(pos2, date.add(const Duration(hours: 8, minutes: 30))),
        LocationSample(pos2, date.add(const Duration(hours: 9, minutes: 30))),

        /// end of stop 3
        LocationSample(pos2, date.add(const Duration(hours: 10, minutes: 30)))
            .addNoise(),
        LocationSample(pos2, date.add(const Duration(hours: 11, minutes: 30)))
            .addNoise(),

        /// end of stop 4
        LocationSample(pos2, date.add(const Duration(hours: 12, minutes: 00))),
        LocationSample(pos2, date.add(const Duration(hours: 12, minutes: 15))),
        LocationSample(pos2, date.add(const Duration(hours: 12, minutes: 30))),

        /// end of stop 5

        /// Gap in data (should get interpolated to Location 1)

        /// Location 0 (Home)
        LocationSample(pos1, date.add(const Duration(hours: 16, seconds: 1))),
        LocationSample(pos1, date.add(const Duration(hours: 20, minutes: 0))),

        /// end of stop 6

        /// Location 0 (Home), New day
        LocationSample(
            pos1, date.add(const Duration(days: 1, hours: 0, minutes: 2))),
      ];

      /// Create stream controller to stream the individual samples
      /// to the MobilityFactory instance
      StreamController<LocationSample> controller =
          StreamController.broadcast();

      // Set up stream
      await MobilityFeatures().startListening(controller.stream);

      int expectedContexts = 6;

      /// Listen to the Context stream
      Stream<MobilityContext> contextStream = MobilityFeatures().contextStream;
      contextStream.listen(
          expectAsync1((c) => printList(c.stops!), count: expectedContexts));

      // Stream all the samples one by one
      for (LocationSample s in samples) {
        controller.add(s);
      }
      controller.close();
    });

    test('Run on Munich Dataset', () async {
      flushFiles();

      final samples = loadDataSet();
      print(samples.length);

      final dates = samples.map((e) => e.dateTime.midnight).toSet().toList();
      printList(dates);

      final onLastDate =
          samples.where((e) => e.dateTime.midnight == dates[1]).toList();
      print(onLastDate.length);

      print(onLastDate.last);

      StreamController<LocationSample> controller =
          StreamController.broadcast();

      await MobilityFeatures().startListening(controller.stream);
      Stream<MobilityContext> mobilityStream = MobilityFeatures().contextStream;

      mobilityStream.listen(expectAsync1((event) {
        print('=' * 150);
        print("Mobility Context Received: ${toJsonString(event.toJson())}");
        print('-' * 50);
        print("STOPS");
        printList(event.stops!);
        print("ALL PLACES");
        printList(event.places!);
        print("SIGNIFICANT PLACES");
        printList(event.significantPlaces!);
        print(
            "TOTAL DURATION (STOPS): ${event.stops?.map((p) => p.duration).reduce((a, b) => a + b)}");
      }, count: 283));

      for (var e in onLastDate) {
        controller.add(e);
      }

      controller.close();
    });
  });
}
