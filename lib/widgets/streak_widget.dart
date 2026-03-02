import 'package:flutter/material.dart';
import '../services/prayer_log_service.dart';
import '../utils/theme.dart';

/// Shows a 7-day completion strip + streak / week / month stats.
/// Reacts automatically to Hive box changes.
class StreakWidget extends StatelessWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Object>(
      valueListenable: PrayerLogService.listenable,
      builder: (context, _, _) {
        final weekLogs = PrayerLogService.getWeekLogs();
        final stats = PrayerLogService.getStats();
        final streak = stats['streak'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: streak > 0 ? Colors.orange : AppColors.textDim,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    streak > 0 ? '$streak day streak' : 'Prayer Streak',
                    style: TextStyle(
                      color: streak > 0 ? Colors.orange : AppColors.textDim,
                      fontSize: 13,
                      fontWeight: streak > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 7-day dot row — oldest left (index 6), today right (index 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final log = weekLogs[6 - i]; // oldest → newest
                  final isToday = i == 6;
                  return _DayDot(done: log.allCompleted, isToday: isToday);
                }),
              ),

              const SizedBox(height: 12),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    value: '${stats['weekCount'] ?? 0}/7',
                    label: 'This Week',
                  ),
                  _StatItem(
                    value: '${stats['monthCount'] ?? 0}/30',
                    label: 'This Month',
                  ),
                  _StatItem(
                    value: '$streak',
                    label: 'Streak',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayDot extends StatelessWidget {
  final bool done;
  final bool isToday;

  const _DayDot({required this.done, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? AppColors.gold.withValues(alpha: 0.2)
            : AppColors.primaryLight,
        border: Border.all(
          color: isToday
              ? AppColors.gold
              : done
                  ? AppColors.gold.withValues(alpha: 0.6)
                  : AppColors.textDim.withValues(alpha: 0.3),
          width: isToday ? 2 : 1.5,
        ),
      ),
      child: done
          ? const Icon(Icons.check, color: AppColors.gold, size: 16)
          : null,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textDim, fontSize: 10),
        ),
      ],
    );
  }
}
