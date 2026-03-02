import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/prayer_log_model.dart';
import '../utils/constants.dart';

class PrayerLogService {
  static Box<PrayerLogModel> get _box =>
      Hive.box<PrayerLogModel>(AppConstants.hiveBoxPrayerLog);

  // ── Key helpers ─────────────────────────────────────────────────────────────

  static String _key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String get todayKey => _key(DateTime.now());

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Get (or create empty) log for [key].
  static PrayerLogModel getLog(String key) =>
      _box.get(key) ?? PrayerLogModel.empty(key);

  static PrayerLogModel get todayLog => getLog(todayKey);

  /// Last [days] days (index 0 = today, last index = oldest).
  static List<PrayerLogModel> getRecentLogs({int days = 30}) {
    final today = DateTime.now();
    return List.generate(days, (i) => getLog(_key(today.subtract(Duration(days: i)))));
  }

  static List<PrayerLogModel> getWeekLogs() => getRecentLogs(days: 7);

  // ── Write ───────────────────────────────────────────────────────────────────

  /// Mark a fard prayer as complete. Optionally records timed duration.
  static Future<void> logPrayer({
    required String dateKey,
    required int fardIndex,
    int durationSeconds = 0,
  }) async {
    final log = getLog(dateKey);
    log.completed[fardIndex] = true;
    log.durations[fardIndex] = durationSeconds;
    await _box.put(dateKey, log);
  }

  // ── Stats ───────────────────────────────────────────────────────────────────

  /// Returns {streak, weekCount, monthCount}.
  /// streak = consecutive full days ending yesterday (or today if complete).
  static Map<String, int> getStats() {
    int streak = 0;
    int weekCount = 0;
    int monthCount = 0;
    bool streakBroken = false;

    final today = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final log = getLog(_key(today.subtract(Duration(days: i))));
      final done = log.allCompleted;

      if (i < 7 && done) weekCount++;
      if (done) monthCount++;

      if (!streakBroken) {
        if (done) {
          streak++;
        } else if (i > 0) {
          // Today can be in-progress; only break on past days
          streakBroken = true;
        }
      }
    }

    return {'streak': streak, 'weekCount': weekCount, 'monthCount': monthCount};
  }

  // ── Reactive ─────────────────────────────────────────────────────────────────

  /// Listenable for reactive UI — rebuilds when any log is written.
  static ValueListenable<Box<PrayerLogModel>> get listenable =>
      _box.listenable();
}
