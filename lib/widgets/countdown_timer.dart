import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/prayer_time_model.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  CountdownTarget? _target;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final provider = context.read<AppProvider>();
    final today = provider.todayTimes;
    if (today == null) return;

    final now = DateTime.now();
    final ct = today.countdownTarget(now, tomorrowFajr: provider.tomorrowTimes?.fajr);

    final diff = ct.target.difference(now);
    setState(() {
      _target = ct;
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final today = provider.todayTimes;

    if (today == null) {
      return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
    }

    final target = _target;
    final isSehri = target?.isSehri ?? true;
    final color = isSehri ? AppColors.sehriBlue : AppColors.iftarOrange;

    // Calculate total window for progress ring
    final now = DateTime.now();
    Duration totalWindow;
    if (isSehri) {
      // Window: last Maghrib → next Fajr
      final lastMaghrib = now.isBefore(today.fajr)
          ? today.maghrib.subtract(const Duration(hours: 24))
          : today.maghrib;
      totalWindow = (target?.target ?? today.fajr).difference(lastMaghrib);
    } else {
      // Window: Fajr → Maghrib
      totalWindow = today.maghrib.difference(today.fajr);
    }

    final elapsed = totalWindow - _remaining;
    final percent = totalWindow.inSeconds > 0
        ? (elapsed.inSeconds / totalWindow.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    final label = target?.label ?? 'Loading...';

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        CircularPercentIndicator(
          radius: 100.0,
          lineWidth: 8.0,
          percent: percent,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSehri ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                _formatDuration(_remaining),
                style: AppTheme.countdown.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                ),
              ),
            ],
          ),
          progressColor: color,
          backgroundColor: AppColors.primaryLight,
          circularStrokeCap: CircularStrokeCap.round,
          animation: false,
        ),
        const SizedBox(height: 16),
        // Quick-glance chips
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InfoChip(
              icon: Icons.nightlight_round,
              label: 'Sehri',
              time: provider.formatTime(today.sehriEnd),
              color: AppColors.sehriBlue,
            ),
            const SizedBox(width: 16),
            _InfoChip(
              icon: Icons.wb_sunny_rounded,
              label: 'Iftar',
              time: provider.formatTime(today.iftarTime),
              color: AppColors.iftarOrange,
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10)),
              Text(time,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
