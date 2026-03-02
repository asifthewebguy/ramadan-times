import 'package:flutter/material.dart';
import '../models/prayer_log_model.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

/// Horizontal row of 5 cells — one per fard prayer — showing completion state.
class PrayerTrackerGrid extends StatelessWidget {
  final PrayerLogModel dayLog;

  const PrayerTrackerGrid({super.key, required this.dayLog});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final done = dayLog.completed[i];
        final timed = done && dayLog.durations[i] > 0;
        return _PrayerCell(
          name: AppConstants.fardNames[i],
          done: done,
          timed: timed,
        );
      }),
    );
  }
}

class _PrayerCell extends StatelessWidget {
  final String name;
  final bool done;
  final bool timed;

  const _PrayerCell({
    required this.name,
    required this.done,
    required this.timed,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.qiblaGreen : AppColors.textDim;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.qiblaGreen.withValues(alpha: 0.15)
                : AppColors.primaryLight,
            border: Border.all(
              color: done
                  ? AppColors.qiblaGreen
                  : AppColors.textDim.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            done ? (timed ? Icons.timer_outlined : Icons.check) : Icons.circle,
            color: done ? color : AppColors.textDim.withValues(alpha: 0.2),
            size: done ? 22 : 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          // 3-letter abbreviation
          name.substring(0, 3),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: done ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
