import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the Adhan when the app is in the foreground at a prayer time.
///
/// Requires `assets/sounds/adhan.mp3` to be present.
/// Call [updatePrayerTimes] whenever prayer times change.
/// Call [setEnabled] to enable/disable audio.
class AdhanService {
  AdhanService._();
  static final AdhanService instance = AdhanService._();

  final AudioPlayer _player = AudioPlayer();
  Timer? _checkTimer;
  List<DateTime> _prayerTimes = [];
  DateTime? _lastPlayedAt;
  bool _enabled = false;

  /// Update the list of prayer DateTimes to watch.
  void updatePrayerTimes(List<DateTime> times) {
    _prayerTimes = times;
  }

  /// Enable or disable the Adhan player.
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _player.stop();
    }
  }

  /// Start the background check timer. Call once from AppProvider.init.
  void startMonitoring() {
    _checkTimer?.cancel();
    // Check every 20 seconds — lightweight, just comparing timestamps
    _checkTimer = Timer.periodic(const Duration(seconds: 20), (_) => _tick());
  }

  void _tick() {
    if (!_enabled || _prayerTimes.isEmpty) return;

    final now = DateTime.now();

    // Guard: don't replay within 5 minutes of last play
    if (_lastPlayedAt != null &&
        now.difference(_lastPlayedAt!).inMinutes < 5) {
      return;
    }

    for (final t in _prayerTimes) {
      final diff = now.difference(t).inSeconds;
      // Within a ±30-second window of the prayer time
      if (diff >= 0 && diff <= 30) {
        _lastPlayedAt = now;
        playAdhan();
        break;
      }
    }
  }

  /// Play the bundled Adhan asset immediately (also called from test button).
  Future<void> playAdhan() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/adhan.mp3'));
    } catch (e) {
      debugPrint('AdhanService: playback failed — $e');
    }
  }

  /// Stop any currently playing Adhan.
  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _checkTimer?.cancel();
    _player.dispose();
  }
}
