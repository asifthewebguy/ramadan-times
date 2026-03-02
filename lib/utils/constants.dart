import 'package:adhan/adhan.dart';

class AppConstants {
  // Kaaba coordinates
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  // Default location (Mecca as ultimate fallback)
  static const double defaultLat = 21.3891;
  static const double defaultLng = 39.8579;
  static const String defaultCity = 'Makkah';

  // SharedPreferences keys
  static const String keyLat = 'last_lat';
  static const String keyLng = 'last_lng';
  static const String keyCity = 'last_city';
  static const String keyCalcMethod = 'calc_method';
  static const String keyMadhab = 'madhab';
  static const String keyTimeFormat = 'time_format_24h';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyNotifEnabled = 'notif_enabled';
  static const String keySehriReminderMin = 'sehri_reminder_min';
  static const String keyIftarAlert = 'iftar_alert';
  static const String keyPrayerTimerEnabled = 'prayer_timer_enabled';
  static const String keyPrayerTimerAutoStart = 'prayer_timer_auto_start';
  static const String keyPrayerTimerLogging = 'prayer_timer_logging';
  static const String keyPrayerTimerHaptic = 'prayer_timer_haptic';
  static const String keyPrayerTimerShowDuration = 'prayer_timer_show_duration';

  // Hive box names
  static const String hiveBoxPrayerLog = 'prayer_log';

  // Prayer names (index 0–4 = fard prayers)
  static const List<String> prayerNames = [
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  // Fard prayer indices only (no Sunrise)
  static const List<int> fardIndices = [0, 2, 3, 4, 5];
  static const List<String> fardNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  // Suggested prayer durations (min, max) in seconds
  static const Map<String, List<int>> suggestedDurations = {
    'Fajr': [5 * 60, 8 * 60],
    'Dhuhr': [10 * 60, 15 * 60],
    'Asr': [5 * 60, 8 * 60],
    'Maghrib': [5 * 60, 8 * 60],
    'Isha': [10 * 60, 12 * 60],
  };

  // Calculation methods list for UI
  static const List<String> calcMethodNames = [
    'Muslim World League',
    'Egyptian General Authority',
    'University of Islamic Sciences, Karachi',
    'Umm Al-Qura, Makkah',
    'ISNA (North America)',
    'Dubai',
    'Turkey (Diyanet)',
    'Tehran',
    'Kuwait',
    'Qatar',
    'Singapore',
  ];

  // Map method name → adhan CalculationParameters factory
  static CalculationParameters calcMethodParams(String name) {
    switch (name) {
      case 'Muslim World League':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'Egyptian General Authority':
        return CalculationMethod.egyptian.getParameters();
      case 'University of Islamic Sciences, Karachi':
        return CalculationMethod.karachi.getParameters();
      case 'Umm Al-Qura, Makkah':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'ISNA (North America)':
        return CalculationMethod.north_america.getParameters();
      case 'Dubai':
        return CalculationMethod.dubai.getParameters();
      case 'Turkey (Diyanet)':
        return CalculationMethod.turkey.getParameters();
      case 'Tehran':
        return CalculationMethod.tehran.getParameters();
      case 'Kuwait':
        return CalculationMethod.kuwait.getParameters();
      case 'Qatar':
        return CalculationMethod.qatar.getParameters();
      case 'Singapore':
        return CalculationMethod.singapore.getParameters();
      default:
        return CalculationMethod.muslim_world_league.getParameters();
    }
  }

  // Sehri reminder options in minutes
  static const List<int> sehriReminderOptions = [15, 30, 45, 60];
}
