import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_time_model.dart';

/// Fetches monthly prayer times from AlAdhan.com API.
/// Returns null on any failure so the caller can fall back to local calculation.
class PrayerApiService {
  static const _baseUrl = 'https://api.aladhan.com/v1';
  static const _timeout = Duration(seconds: 10);

  /// Returns all [PrayerTimeModel]s for the given month, or null on failure.
  /// Results are cached in SharedPreferences so the API is only called once
  /// per month per location.
  static Future<List<PrayerTimeModel>?> getMonthlyTimes({
    required double lat,
    required double lng,
    required int year,
    required int month,
    required int aladhanMethod,
    required int school, // 0 = Shafi'i, 1 = Hanafi
  }) async {
    final cacheKey = _cacheKey(lat, lng, year, month);

    // Try cache first
    final cached = await _loadCache(cacheKey);
    if (cached != null) {
      return _parseResponse(cached, year, month);
    }

    // Fetch from API
    try {
      final uri = Uri.parse('$_baseUrl/calendar/$year/$month').replace(
        queryParameters: {
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'method': aladhanMethod.toString(),
          'school': school.toString(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final body = response.body;
      final parsed = _parseResponse(body, year, month);
      if (parsed == null) return null;

      await _saveCache(cacheKey, body);
      return parsed;
    } catch (_) {
      return null;
    }
  }

  static List<PrayerTimeModel>? _parseResponse(String jsonStr, int year, int month) {
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (decoded['code'] != 200) return null;

      final data = decoded['data'] as List<dynamic>;
      final result = <PrayerTimeModel>[];

      for (final entry in data) {
        final timings = entry['timings'] as Map<String, dynamic>;
        final dateInfo = entry['date']['gregorian'];
        final day = int.parse(dateInfo['day'] as String);

        final fajr = _parseTime(timings['Fajr'] as String, year, month, day);
        final sunrise = _parseTime(timings['Sunrise'] as String, year, month, day);
        final dhuhr = _parseTime(timings['Dhuhr'] as String, year, month, day);
        final asr = _parseTime(timings['Asr'] as String, year, month, day);
        final maghrib = _parseTime(timings['Maghrib'] as String, year, month, day);
        final isha = _parseTime(timings['Isha'] as String, year, month, day);

        if (fajr == null || sunrise == null || dhuhr == null ||
            asr == null || maghrib == null || isha == null) {
          continue;
        }

        result.add(PrayerTimeModel(
          fajr: fajr,
          sunrise: sunrise,
          dhuhr: dhuhr,
          asr: asr,
          maghrib: maghrib,
          isha: isha,
          date: DateTime(year, month, day),
        ));
      }

      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  /// Parses AlAdhan time string like "05:04 (+06)" or "05:04 (BD)" into DateTime.
  static DateTime? _parseTime(String timeStr, int year, int month, int day) {
    try {
      // Extract just the "HH:MM" part before the space
      final hhmm = timeStr.split(' ').first.trim();
      final parts = hhmm.split(':');
      if (parts.length < 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  static String _cacheKey(double lat, double lng, int year, int month) {
    final latR = lat.toStringAsFixed(1);
    final lngR = lng.toStringAsFixed(1);
    return 'prayer_api_${year}_${month}_${latR}_$lngR';
  }

  static Future<String?> _loadCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> _saveCache(String key, String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json);
  }
}
