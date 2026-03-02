import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/compass_service.dart';
import '../services/prayer_time_service.dart';
import '../utils/theme.dart';
import '../widgets/compass_widget.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final CompassService _compassService = CompassService();
  final PrayerTimeService _prayerService = PrayerTimeService();

  double _heading = 0.0;
  double _accuracy = 1.0;
  bool _calibrating = false;

  @override
  void initState() {
    super.initState();
    if (!_compassService.isAvailable) return;

    _compassService.headingStream.listen((heading) {
      if (heading != null && mounted) {
        setState(() => _heading = heading);
      }
    });

    _compassService.accuracyStream.listen((acc) {
      if (mounted) {
        setState(() {
          _accuracy = acc;
          _calibrating = acc < 0.3;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final qibla = _prayerService.getQiblaDirection(provider.lat, provider.lng);
    final distanceKm = _prayerService.distanceToMakkah(provider.lat, provider.lng);

    // User is essentially at the Kaaba
    if (distanceKm < 1.0) {
      return _AtKaabaScreen();
    }

    if (!_compassService.isAvailable) {
      return _NoSensorScreen(qiblaDirection: qibla, distanceKm: distanceKm, provider: provider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Qibla')),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Calibration notice
                    if (_calibrating) _CalibrationBanner(),

                    // Compass
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: CompassWidget(
                        key: const ValueKey('compass'),
                        deviceHeading: _heading,
                        qiblaDirection: qibla,
                        accuracy: _accuracy,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Qibla degree badge
                    _DegreeBadge(heading: _heading, qibla: qibla),

                    const SizedBox(height: 20),

                    // Info cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _InfoCard(
                          icon: Icons.explore_outlined,
                          label: 'Qibla Direction',
                          value: '${qibla.toStringAsFixed(1)}°',
                        ),
                        const SizedBox(width: 16),
                        _InfoCard(
                          icon: Icons.location_on_outlined,
                          label: 'Distance to Makkah',
                          value: '${distanceKm.toStringAsFixed(0)} km',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      provider.city,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${provider.lat.toStringAsFixed(4)}°, ${provider.lng.toStringAsFixed(4)}°',
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DegreeBadge extends StatelessWidget {
  final double heading;
  final double qibla;

  const _DegreeBadge({required this.heading, required this.qibla});

  bool get _isAligned {
    final diff = ((qibla - heading) % 360).abs();
    final normalised = diff > 180 ? 360 - diff : diff;
    return normalised <= 3.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isAligned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.qiblaGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.qiblaGreen.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.qiblaGreen, size: 18),
            SizedBox(width: 8),
            Text(
              'Facing Qibla',
              style: TextStyle(
                color: AppColors.qiblaGreen,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final diff = (qibla - heading) % 360;
    final normalised = diff < 0 ? diff + 360 : diff;
    final turn = normalised <= 180 ? 'right' : 'left';
    final degrees = normalised <= 180 ? normalised : 360 - normalised;

    return Text(
      'Turn ${degrees.toStringAsFixed(0)}° $turn',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CalibrationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Compass needs calibration. Move your device in a figure-8 pattern.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSensorScreen extends StatelessWidget {
  final double qiblaDirection;
  final double distanceKm;
  final AppProvider provider;

  const _NoSensorScreen({
    required this.qiblaDirection,
    required this.distanceKm,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off_outlined,
                  color: AppColors.textDim, size: 64),
              const SizedBox(height: 16),
              const Text('No Compass Sensor',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'Your device does not have a magnetometer. Use the Qibla bearing below to determine direction manually.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.explore, color: AppColors.gold, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      '${qiblaDirection.toStringAsFixed(1)}°',
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 48,
                          fontWeight: FontWeight.w700),
                    ),
                    const Text('from North',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 12),
                    Text(
                      '${distanceKm.toStringAsFixed(0)} km to Makkah',
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AtKaabaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mosque, color: AppColors.gold, size: 72),
              SizedBox(height: 16),
              Text(
                'You are at the Holy Mosque',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Pray in any direction facing the Kaaba.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
