import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PrayerTimeCard extends StatelessWidget {
  final String name;
  final String time;
  final IconData icon;
  final bool isNext;
  final bool isPassed;
  final bool tappable;
  final VoidCallback? onTap;

  const PrayerTimeCard({
    super.key,
    required this.name,
    required this.time,
    required this.icon,
    this.isNext = false,
    this.isPassed = false,
    this.tappable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isPassed ? AppColors.textDim : AppColors.textPrimary;
    final iconColor = isPassed
        ? AppColors.textDim
        : (isNext ? AppColors.gold : AppColors.textSecondary);

    return GestureDetector(
      onTap: tappable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isNext
              ? AppColors.gold.withValues(alpha: 0.08)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: isNext
              ? Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isNext
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: AppTheme.prayerName.copyWith(color: textColor),
              ),
            ),
            if (isNext)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NEXT',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Text(
              time,
              style: AppTheme.prayerTime.copyWith(color: textColor),
            ),
            if (tappable && !isPassed) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.textDim,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Prayer icon mapping
IconData prayerIcon(String name) {
  switch (name) {
    case 'Fajr':
      return Icons.nightlight_round;
    case 'Sunrise':
      return Icons.brightness_7;
    case 'Dhuhr':
      return Icons.wb_sunny;
    case 'Asr':
      return Icons.brightness_5;
    case 'Maghrib':
      return Icons.brightness_4;
    case 'Isha':
      return Icons.dark_mode;
    default:
      return Icons.access_time;
  }
}
