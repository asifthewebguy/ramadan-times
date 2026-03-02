import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_app/models/prayer_log_model.dart';
import 'package:ramadan_app/services/prayer_time_service.dart';
import 'package:ramadan_app/utils/constants.dart';

void main() {
  // ── PrayerLogModel ────────────────────────────────────────────────────────

  group('PrayerLogModel', () {
    test('empty() creates a log with all completions false and durations 0', () {
      final log = PrayerLogModel.empty('2024-03-10');
      expect(log.dateKey, '2024-03-10');
      expect(log.completed.length, 5);
      expect(log.durations.length, 5);
      expect(log.completedCount, 0);
      expect(log.allCompleted, false);
      expect(log.completed.every((c) => c == false), true);
      expect(log.durations.every((d) => d == 0), true);
    });

    test('completedCount reflects number of true values', () {
      final log = PrayerLogModel(
        dateKey: '2024-03-10',
        completed: [true, false, true, true, false],
        durations: [300, 0, 420, 360, 0],
      );
      expect(log.completedCount, 3);
      expect(log.allCompleted, false);
    });

    test('allCompleted is true only when all 5 are marked', () {
      final all = PrayerLogModel(
        dateKey: '2024-03-10',
        completed: [true, true, true, true, true],
        durations: [300, 600, 420, 360, 720],
      );
      expect(all.allCompleted, true);
      expect(all.completedCount, 5);
    });

    test('allCompleted is false if even one prayer is missing', () {
      final partial = PrayerLogModel(
        dateKey: '2024-03-10',
        completed: [true, true, true, true, false],
        durations: [300, 600, 420, 360, 0],
      );
      expect(partial.allCompleted, false);
    });
  });

  // ── AppConstants ──────────────────────────────────────────────────────────

  group('AppConstants', () {
    test('fardNames has exactly 5 entries', () {
      expect(AppConstants.fardNames.length, 5);
    });

    test('fardNames indexOf maps prayer name to correct index', () {
      expect(AppConstants.fardNames.indexOf('Fajr'), 0);
      expect(AppConstants.fardNames.indexOf('Dhuhr'), 1);
      expect(AppConstants.fardNames.indexOf('Asr'), 2);
      expect(AppConstants.fardNames.indexOf('Maghrib'), 3);
      expect(AppConstants.fardNames.indexOf('Isha'), 4);
      expect(AppConstants.fardNames.indexOf('Sunrise'), -1);
    });

    test('suggestedDurations covers all 5 fard prayers with valid ranges', () {
      for (final name in AppConstants.fardNames) {
        expect(AppConstants.suggestedDurations.containsKey(name), true,
            reason: 'Missing duration for $name');
        final range = AppConstants.suggestedDurations[name]!;
        expect(range.length, 2);
        expect(range[0], lessThan(range[1]),
            reason: 'Min should be less than max for $name');
        expect(range[0], greaterThan(0));
      }
    });

    test('calcMethodNames has 11 entries matching PRD spec', () {
      expect(AppConstants.calcMethodNames.length, 11);
    });

    test('calcMethodParams returns params for every method name', () {
      for (final name in AppConstants.calcMethodNames) {
        expect(
          () => AppConstants.calcMethodParams(name),
          returnsNormally,
          reason: 'calcMethodParams should not throw for "$name"',
        );
      }
    });

    test('sehriReminderOptions are all positive and in ascending order', () {
      final opts = AppConstants.sehriReminderOptions;
      expect(opts.every((v) => v > 0), true);
      for (int i = 1; i < opts.length; i++) {
        expect(opts[i], greaterThan(opts[i - 1]));
      }
    });
  });

  // ── PrayerTimeService ─────────────────────────────────────────────────────

  group('PrayerTimeService — Qibla', () {
    final service = PrayerTimeService();

    test('Qibla from London (~51.5°N, ~0.1°W) is roughly northeast (~118°)',
        () {
      final qibla = service.getQiblaDirection(51.5, -0.1);
      // London to Makkah is roughly 118–120° from North
      expect(qibla, inInclusiveRange(110.0, 130.0));
    });

    test('Qibla from New York (~40.7°N, ~74°W) is roughly east-northeast (~59°)',
        () {
      final qibla = service.getQiblaDirection(40.7, -74.0);
      expect(qibla, inInclusiveRange(50.0, 70.0));
    });

    test('getQiblaDirection does not throw when called from Makkah', () {
      // Qibla bearing is undefined when the point IS the Kaaba; just verify
      // no exception is thrown and the result is a finite number.
      final qibla = service.getQiblaDirection(
          AppConstants.kaabaLat, AppConstants.kaabaLng);
      expect(qibla.isFinite, true);
    });

    test('distanceToMakkah from London is approximately 4500–5200 km', () {
      // Great-circle distance London (51.5°N, 0.1°W) → Makkah ≈ 4800 km
      final dist = service.distanceToMakkah(51.5, -0.1);
      expect(dist, inInclusiveRange(4500.0, 5200.0));
    });

    test('distanceToMakkah from Makkah itself is < 1 km', () {
      final dist = service.distanceToMakkah(
          AppConstants.kaabaLat, AppConstants.kaabaLng);
      expect(dist, lessThan(1.0));
    });
  });

  group('PrayerTimeService — prayer times', () {
    final service = PrayerTimeService();

    test('getPrayerTimes returns a model with all 6 times set', () {
      final model = service.getPrayerTimes(
        lat: 51.5,
        lng: -0.1,
        date: DateTime(2024, 3, 10),
        calcMethodName: 'Muslim World League',
        madhab: "Shafi'i",
      );
      // All 6 times should be valid DateTime values (not null)
      expect(model.fajr, isA<DateTime>());
      expect(model.sunrise, isA<DateTime>());
      expect(model.dhuhr, isA<DateTime>());
      expect(model.asr, isA<DateTime>());
      expect(model.maghrib, isA<DateTime>());
      expect(model.isha, isA<DateTime>());
    });

    test('prayer times are in chronological order', () {
      final model = service.getPrayerTimes(
        lat: 51.5,
        lng: -0.1,
        date: DateTime(2024, 3, 10),
        calcMethodName: 'Muslim World League',
        madhab: "Shafi'i",
      );
      expect(model.fajr.isBefore(model.sunrise), true);
      expect(model.sunrise.isBefore(model.dhuhr), true);
      expect(model.dhuhr.isBefore(model.asr), true);
      expect(model.asr.isBefore(model.maghrib), true);
      expect(model.maghrib.isBefore(model.isha), true);
    });

    test('sehriEnd equals fajr and iftarTime equals maghrib', () {
      final model = service.getPrayerTimes(
        lat: 21.4,
        lng: 39.8,
        date: DateTime(2024, 3, 10),
        calcMethodName: 'Umm Al-Qura, Makkah',
        madhab: "Shafi'i",
      );
      expect(model.sehriEnd, model.fajr);
      expect(model.iftarTime, model.maghrib);
    });

    test('getMonthlyTimes returns 30 or 31 entries for the given month', () {
      final models = service.getMonthlyTimes(
        lat: 51.5,
        lng: -0.1,
        year: 2024,
        month: 3,
        calcMethodName: 'Muslim World League',
        madhab: "Shafi'i",
      );
      expect(models.length, 31); // March has 31 days
    });
  });
}
