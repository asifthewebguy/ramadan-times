import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/prayer_time_model.dart';

/// Writes prayer time data to the Android home screen widgets.
/// Uses the home_widget package, which stores data in SharedPreferences
/// under the key `HomeWidgetPlugin.{packageName}` — read by the
/// native AppWidgetProvider.
class WidgetService {
  WidgetService._();

  static const _appGroupId = 'com.asifchowdhury.ramadantimes';

  /// Call this after prayer times are (re)calculated or on app resume.
  static Future<void> update({
    required PrayerTimeModel today,
    required String Function(DateTime) formatTime,
    required String hijriDate,
    bool use24h = false,
  }) async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      final now = DateTime.now();
      final next = today.nextPrayer(now);

      // Small widget data
      await HomeWidget.saveWidgetData<String>(
        'next_prayer_name',
        next?.key ?? 'Prayer',
      );
      await HomeWidget.saveWidgetData<String>(
        'next_prayer_time',
        next != null ? formatTime(next.value) : '--:--',
      );

      // Medium widget data
      await HomeWidget.saveWidgetData<String>('hijri_date', hijriDate);
      await HomeWidget.saveWidgetData<String>(
          'fajr_time', formatTime(today.fajr));
      await HomeWidget.saveWidgetData<String>(
          'dhuhr_time', formatTime(today.dhuhr));
      await HomeWidget.saveWidgetData<String>(
          'asr_time', formatTime(today.asr));
      await HomeWidget.saveWidgetData<String>(
          'maghrib_time', formatTime(today.maghrib));
      await HomeWidget.saveWidgetData<String>(
          'isha_time', formatTime(today.isha));

      // Trigger both widget providers to re-draw
      await HomeWidget.updateWidget(
        androidName: 'PrayerWidgetSmall',
      );
      await HomeWidget.updateWidget(
        androidName: 'PrayerWidgetMedium',
      );
    } catch (e) {
      debugPrint('WidgetService: update failed — $e');
    }
  }
}
