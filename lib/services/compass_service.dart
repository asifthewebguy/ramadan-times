import 'package:flutter_compass/flutter_compass.dart';

class CompassService {
  /// Returns true if the device has a magnetometer sensor.
  bool get isAvailable => FlutterCompass.events != null;

  /// Stream of compass headings in degrees (0–360, 0 = North).
  /// Emits null when the sensor is unavailable or uncalibrated.
  Stream<double?> get headingStream {
    final events = FlutterCompass.events;
    if (events == null) return const Stream.empty();
    return events.map((e) => e.heading);
  }

  /// Stream of sensor accuracy (0.0–1.0 where 1.0 = full accuracy).
  /// Only available on Android; returns 1.0 on iOS.
  Stream<double> get accuracyStream {
    final events = FlutterCompass.events;
    if (events == null) return const Stream.empty();
    return events.map((e) => e.accuracy ?? 1.0);
  }
}
