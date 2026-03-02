import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import '../models/prayer_time_model.dart';
import '../utils/constants.dart';

class PrayerTimeService {
  /// Calculate prayer times for a given [date], [lat]/[lng],
  /// [calcMethodName] and [madhab] ('Hanafi' or 'Shafi\'i').
  PrayerTimeModel getPrayerTimes({
    required double lat,
    required double lng,
    required DateTime date,
    required String calcMethodName,
    required String madhab,
  }) {
    final params = AppConstants.calcMethodParams(calcMethodName);
    params.madhab = madhab == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;

    final coordinates = Coordinates(lat, lng);
    final dateComponents = DateComponents(date.year, date.month, date.day);
    final times = PrayerTimes(coordinates, dateComponents, params);

    return PrayerTimeModel.fromAdhan(times, date);
  }

  /// Calculate prayer times for all days in [year]/[month].
  List<PrayerTimeModel> getMonthlyTimes({
    required double lat,
    required double lng,
    required int year,
    required int month,
    required String calcMethodName,
    required String madhab,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return List.generate(daysInMonth, (i) {
      final date = DateTime(year, month, i + 1);
      return getPrayerTimes(
        lat: lat,
        lng: lng,
        date: date,
        calcMethodName: calcMethodName,
        madhab: madhab,
      );
    });
  }

  /// Compute Qibla direction in degrees from [lat]/[lng].
  double getQiblaDirection(double lat, double lng) {
    final coordinates = Coordinates(lat, lng);
    return Qibla(coordinates).direction;
  }

  /// Great-circle distance to the Kaaba in kilometers.
  double distanceToMakkah(double lat, double lng) {
    const double r = 6371.0;
    final lat1 = lat * math.pi / 180;
    final lat2 = AppConstants.kaabaLat * math.pi / 180;
    final dLat = (AppConstants.kaabaLat - lat) * math.pi / 180;
    final dLng = (AppConstants.kaabaLng - lng) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }
}
