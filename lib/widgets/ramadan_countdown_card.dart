import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../utils/theme.dart';

/// Shows a countdown to the next Ramadan when the current Hijri month is not Ramadan (9).
/// Hidden during Ramadan itself.
class RamadanCountdownCard extends StatelessWidget {
  const RamadanCountdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.now();

    // Ramadan is month 9. If we're in Ramadan, show nothing.
    if (hijri.hMonth == 9) return const SizedBox.shrink();

    final daysLeft = _daysUntilRamadan(hijri);
    final nextRamadanYear = hijri.hMonth < 9 ? hijri.hYear : hijri.hYear + 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.12),
            AppColors.cardBg,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nightlight_round, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ramadan $nextRamadanYear AH',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  daysLeft == 1
                      ? 'Begins tomorrow!'
                      : 'Begins in $daysLeft days',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$daysLeft',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  int _daysUntilRamadan(HijriCalendar hijri) {
    // Build a Hijri date for Ramadan 1 of the nearest upcoming year
    final targetYear = hijri.hMonth < 9 ? hijri.hYear : hijri.hYear + 1;
    final ramadanStart = HijriCalendar()
      ..hYear = targetYear
      ..hMonth = 9
      ..hDay = 1;

    final todayGregorian = DateTime.now();
    final ramadanGregorian = ramadanStart.hijriToGregorian(
      ramadanStart.hYear,
      ramadanStart.hMonth,
      ramadanStart.hDay,
    );

    final diff = ramadanGregorian
        .difference(DateTime(todayGregorian.year, todayGregorian.month, todayGregorian.day))
        .inDays;

    return diff.clamp(0, 999);
  }
}
