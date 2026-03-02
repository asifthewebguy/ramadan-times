import 'package:hive/hive.dart';

part 'prayer_log_model.g.dart';

/// Stores daily prayer completion data.
/// [completed] has 5 entries for [Fajr, Dhuhr, Asr, Maghrib, Isha].
/// [durations] stores elapsed seconds for each prayer (0 if not timed).
@HiveType(typeId: 0)
class PrayerLogModel extends HiveObject {
  @HiveField(0)
  String dateKey; // Format: "YYYY-MM-DD"

  @HiveField(1)
  List<bool> completed; // length 5

  @HiveField(2)
  List<int> durations; // length 5, seconds

  PrayerLogModel({
    required this.dateKey,
    required this.completed,
    required this.durations,
  });

  factory PrayerLogModel.empty(String dateKey) {
    return PrayerLogModel(
      dateKey: dateKey,
      completed: List.filled(5, false),
      durations: List.filled(5, 0),
    );
  }

  int get completedCount => completed.where((c) => c).length;

  bool get allCompleted => completed.every((c) => c);
}
