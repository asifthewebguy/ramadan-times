import 'package:adhan/adhan.dart';

class PrayerTimeModel {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime date;

  PrayerTimeModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
  });

  factory PrayerTimeModel.fromAdhan(PrayerTimes times, DateTime date) {
    return PrayerTimeModel(
      fajr: times.fajr,
      sunrise: times.sunrise,
      dhuhr: times.dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
      date: date,
    );
  }

  /// Sehri end = Fajr time
  DateTime get sehriEnd => fajr;

  /// Iftar time = Maghrib time
  DateTime get iftarTime => maghrib;

  /// All six times as an ordered list [fajr, sunrise, dhuhr, asr, maghrib, isha]
  List<DateTime> get allTimes => [fajr, sunrise, dhuhr, asr, maghrib, isha];

  /// The 5 fard prayer times [fajr, dhuhr, asr, maghrib, isha]
  List<DateTime> get fardTimes => [fajr, dhuhr, asr, maghrib, isha];

  /// Returns the next prayer and its time after [now], or null if all passed.
  MapEntry<String, DateTime>? nextPrayer(DateTime now) {
    final names = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final times = allTimes;
    for (int i = 0; i < times.length; i++) {
      if (times[i].isAfter(now)) {
        return MapEntry(names[i], times[i]);
      }
    }
    return null;
  }

  /// Countdown target based on current time:
  /// - Before Fajr → Sehri end (Fajr)
  /// - Fajr to Maghrib → Iftar (Maghrib)
  /// - After Maghrib → tomorrow's Sehri (null if tomorrow not provided)
  CountdownTarget countdownTarget(DateTime now, {DateTime? tomorrowFajr}) {
    if (now.isBefore(fajr)) {
      return CountdownTarget(
        label: 'Sehri ends in',
        target: fajr,
        isSehri: true,
      );
    } else if (now.isBefore(maghrib)) {
      return CountdownTarget(
        label: 'Iftar in',
        target: maghrib,
        isSehri: false,
      );
    } else {
      return CountdownTarget(
        label: 'Sehri ends in',
        target: tomorrowFajr ?? fajr.add(const Duration(hours: 24)),
        isSehri: true,
      );
    }
  }
}

class CountdownTarget {
  final String label;
  final DateTime target;
  final bool isSehri;

  const CountdownTarget({
    required this.label,
    required this.target,
    required this.isSehri,
  });
}
