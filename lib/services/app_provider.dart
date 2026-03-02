import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_time_model.dart';
import '../services/prayer_time_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

enum AppStatus { loading, ready, locationError, calculationError }

class AppProvider extends ChangeNotifier {
  final PrayerTimeService _prayerService = PrayerTimeService();
  final LocationService _locationService = LocationService();

  AppStatus _status = AppStatus.loading;
  String? _locationError;

  double _lat = AppConstants.defaultLat;
  double _lng = AppConstants.defaultLng;
  String _city = AppConstants.defaultCity;

  PrayerTimeModel? _todayTimes;
  PrayerTimeModel? _tomorrowTimes;
  List<PrayerTimeModel> _monthlyTimes = [];

  // Settings
  String _calcMethod = 'Muslim World League';
  String _madhab = "Shafi'i";
  bool _use24h = false;
  bool _prayerTimerEnabled = false;
  bool _prayerTimerAutoStart = false;
  bool _prayerTimerLogging = true;
  bool _prayerTimerHaptic = true;
  bool _prayerTimerShowDuration = true;
  bool _notifEnabled = true;
  int _sehriReminderMin = 30;
  bool _iftarAlert = true;

  // Getters
  AppStatus get status => _status;
  String? get locationError => _locationError;
  double get lat => _lat;
  double get lng => _lng;
  String get city => _city;
  PrayerTimeModel? get todayTimes => _todayTimes;
  PrayerTimeModel? get tomorrowTimes => _tomorrowTimes;
  List<PrayerTimeModel> get monthlyTimes => _monthlyTimes;
  String get calcMethod => _calcMethod;
  String get madhab => _madhab;
  bool get use24h => _use24h;
  bool get prayerTimerEnabled => _prayerTimerEnabled;
  bool get prayerTimerAutoStart => _prayerTimerAutoStart;
  bool get prayerTimerLogging => _prayerTimerLogging;
  bool get prayerTimerHaptic => _prayerTimerHaptic;
  bool get prayerTimerShowDuration => _prayerTimerShowDuration;
  bool get notifEnabled => _notifEnabled;
  int get sehriReminderMin => _sehriReminderMin;
  bool get iftarAlert => _iftarAlert;

  /// Full initialization: load settings → get location → calculate times.
  Future<void> initialize() async {
    _status = AppStatus.loading;
    notifyListeners();

    await _loadSettings();

    try {
      final result = await _locationService.getCurrentLocation();
      _lat = result.lat;
      _lng = result.lng;
      _city = result.city;
    } on LocationError catch (e) {
      _locationError = _locationErrorMessage(e);
      // Continue with cached/default coords
    } catch (_) {
      _locationError = 'Could not determine location. Using last known position.';
    }

    _calculateTimes();
    _status = AppStatus.ready;
    notifyListeners();
  }

  /// Recalculate times with a manually selected location.
  Future<void> setLocation(double lat, double lng, String city) async {
    _lat = lat;
    _lng = lng;
    _city = city;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyLat, lat);
    await prefs.setDouble(AppConstants.keyLng, lng);
    await prefs.setString(AppConstants.keyCity, city);
    _calculateTimes();
    notifyListeners();
  }

  void setCalcMethod(String method) async {
    _calcMethod = method;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCalcMethod, method);
    _calculateTimes();
    notifyListeners();
  }

  void setMadhab(String madhab) async {
    _madhab = madhab;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyMadhab, madhab);
    _calculateTimes();
    notifyListeners();
  }

  void setTimeFormat(bool use24h) async {
    _use24h = use24h;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyTimeFormat, use24h);
    notifyListeners();
  }

  void setPrayerTimerEnabled(bool value) async {
    _prayerTimerEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyPrayerTimerEnabled, value);
    notifyListeners();
  }

  void setPrayerTimerAutoStart(bool value) async {
    _prayerTimerAutoStart = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyPrayerTimerAutoStart, value);
    notifyListeners();
  }

  void setPrayerTimerLogging(bool value) async {
    _prayerTimerLogging = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyPrayerTimerLogging, value);
    notifyListeners();
  }

  void setPrayerTimerHaptic(bool value) async {
    _prayerTimerHaptic = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyPrayerTimerHaptic, value);
    notifyListeners();
  }

  void setPrayerTimerShowDuration(bool value) async {
    _prayerTimerShowDuration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyPrayerTimerShowDuration, value);
    notifyListeners();
  }

  void setNotifEnabled(bool value) async {
    _notifEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotifEnabled, value);
    notifyListeners();
  }

  void setSehriReminderMin(int minutes) async {
    _sehriReminderMin = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keySehriReminderMin, minutes);
    notifyListeners();
  }

  void setIftarAlert(bool value) async {
    _iftarAlert = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIftarAlert, value);
    notifyListeners();
  }

  void _calculateTimes() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    _todayTimes = _prayerService.getPrayerTimes(
      lat: _lat,
      lng: _lng,
      date: now,
      calcMethodName: _calcMethod,
      madhab: _madhab,
    );
    _tomorrowTimes = _prayerService.getPrayerTimes(
      lat: _lat,
      lng: _lng,
      date: tomorrow,
      calcMethodName: _calcMethod,
      madhab: _madhab,
    );
    _monthlyTimes = _prayerService.getMonthlyTimes(
      lat: _lat,
      lng: _lng,
      year: now.year,
      month: now.month,
      calcMethodName: _calcMethod,
      madhab: _madhab,
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _calcMethod = prefs.getString(AppConstants.keyCalcMethod) ?? 'Muslim World League';
    _madhab = prefs.getString(AppConstants.keyMadhab) ?? "Shafi'i";
    _use24h = prefs.getBool(AppConstants.keyTimeFormat) ?? false;
    _prayerTimerEnabled = prefs.getBool(AppConstants.keyPrayerTimerEnabled) ?? false;
    _prayerTimerAutoStart = prefs.getBool(AppConstants.keyPrayerTimerAutoStart) ?? false;
    _prayerTimerLogging = prefs.getBool(AppConstants.keyPrayerTimerLogging) ?? true;
    _prayerTimerHaptic = prefs.getBool(AppConstants.keyPrayerTimerHaptic) ?? true;
    _prayerTimerShowDuration = prefs.getBool(AppConstants.keyPrayerTimerShowDuration) ?? true;
    _notifEnabled = prefs.getBool(AppConstants.keyNotifEnabled) ?? true;
    _sehriReminderMin = prefs.getInt(AppConstants.keySehriReminderMin) ?? 30;
    _iftarAlert = prefs.getBool(AppConstants.keyIftarAlert) ?? true;

    // Load cached location if exists
    final lat = prefs.getDouble(AppConstants.keyLat);
    final lng = prefs.getDouble(AppConstants.keyLng);
    final city = prefs.getString(AppConstants.keyCity);
    if (lat != null && lng != null) {
      _lat = lat;
      _lng = lng;
      _city = city ?? AppConstants.defaultCity;
    }
  }

  String _locationErrorMessage(LocationError error) {
    switch (error) {
      case LocationError.denied:
        return 'Location permission denied. Using cached location.';
      case LocationError.deniedForever:
        return 'Location permission permanently denied. Enable it in Settings.';
      case LocationError.serviceDisabled:
        return 'Location services disabled. Using cached location.';
      case LocationError.unknown:
        return 'Could not determine location. Using last known position.';
    }
  }

  /// Format a [DateTime] according to current time format preference.
  String formatTime(DateTime time) {
    if (_use24h) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    final hour = time.hour == 0
        ? 12
        : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
