import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/prayer_time_model.dart';

/// Notification channel IDs
const _kChannelId = 'ramadan_times_main';
const _kChannelName = 'Ramadan Times';
const _kChannelDesc = 'Prayer time alerts, Sehri reminders and Iftar notifications';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Initialisation ──────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // Request POST_NOTIFICATIONS (Android 13+)
      await android?.requestNotificationsPermission();
      // Request SCHEDULE_EXACT_ALARM — opens system settings page once
      await android?.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  // ── Schedule / cancel ───────────────────────────────────────────────────────

  /// Schedule all alerts for the next [days] days of prayer times.
  /// Cancels any previously scheduled notifications first.
  static Future<void> scheduleAll({
    required List<PrayerTimeModel> upcomingDays,
    required bool notifEnabled,
    required int sehriReminderMin,
    required bool iftarAlert,
    required Map<String, bool> perPrayerAlerts, // e.g. {'Fajr': true, ...}
  }) async {
    await _plugin.cancelAll();
    if (!notifEnabled) return;

    int id = 0;
    final now = DateTime.now();

    for (final day in upcomingDays) {
      // ── Sehri reminder ────────────────────────────────────────────────────
      final sehriTime = day.fajr.subtract(Duration(minutes: sehriReminderMin));
      if (sehriTime.isAfter(now)) {
        await _schedule(
          id: id++,
          title: 'Sehri Reminder',
          body: 'Sehri ends in $sehriReminderMin minutes at ${_fmt(day.fajr)}',
          at: sehriTime,
          sound: 'default',
        );
      }

      // ── Iftar alert (at Maghrib) ──────────────────────────────────────────
      if (iftarAlert && day.maghrib.isAfter(now)) {
        await _schedule(
          id: id++,
          title: 'Iftar Time',
          body: 'Maghrib: ${_fmt(day.maghrib)} — Iftar Mubarak!',
          at: day.maghrib,
          sound: 'default',
        );
      }

      // ── Per-prayer alerts ─────────────────────────────────────────────────
      final prayerEntries = {
        'Fajr': day.fajr,
        'Dhuhr': day.dhuhr,
        'Asr': day.asr,
        'Maghrib': day.maghrib,
        'Isha': day.isha,
      };
      for (final entry in prayerEntries.entries) {
        if (perPrayerAlerts[entry.key] == true && entry.value.isAfter(now)) {
          await _schedule(
            id: id++,
            title: '${entry.key} Time',
            body: 'It\'s time for ${entry.key} prayer (${_fmt(entry.value)})',
            at: entry.value,
            sound: 'default',
          );
        }
      }

      // Guard against iOS 64-notification limit
      if (id >= 60) break;
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String sound,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );
      const iosDetails = DarwinNotificationDetails(sound: 'default');
      const details = NotificationDetails(
          android: androidDetails, iOS: iosDetails);

      // Use exact scheduling if SCHEDULE_EXACT_ALARM is granted,
      // fall back to inexact (within ~1 min) if not.
      final canExact = Platform.isAndroid
          ? await _plugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.canScheduleExactNotifications() ??
              false
          : true;

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _toTZ(at),
        details,
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService: failed to schedule #$id — $e');
    }
  }

  /// Convert a local [DateTime] to a [tz.TZDateTime] in UTC so the
  /// notification fires at the correct wall-clock moment regardless of
  /// timezone database lookup.
  static tz.TZDateTime _toTZ(DateTime local) {
    final utc = local.toUtc();
    return tz.TZDateTime(
        tz.UTC, utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}
