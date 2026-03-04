import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/prayer_log_model.dart';
import '../services/app_provider.dart';
import '../services/prayer_log_service.dart';
import '../screens/prayer_timer_screen.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/prayer_time_card.dart';
import '../widgets/prayer_tracker_grid.dart';
import '../widgets/streak_widget.dart';
import '../widgets/ayah_card.dart';
import '../widgets/dua_day_card.dart';
import '../widgets/ramadan_countdown_card.dart';

// English Islamic month names
const _kHijriMonths = [
  'Muharram', 'Safar', "Rabi' I", "Rabi' II",
  'Jumada I', 'Jumada II', 'Rajab', "Sha'ban",
  'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _gradientTimer;

  @override
  void initState() {
    super.initState();
    // Refresh every minute so the gradient transitions at Fajr / Maghrib
    _gradientTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _gradientTimer?.cancel();
    super.dispose();
  }

  /// True during the daytime fasting window (Fajr → Maghrib).
  bool _isDaytime(AppProvider provider) {
    final today = provider.todayTimes;
    if (today == null) return false;
    final now = DateTime.now();
    return now.isAfter(today.fajr) && now.isBefore(today.maghrib);
  }

  String _hijriDateString() {
    final h = HijriCalendar.now();
    final month = _kHijriMonths[h.hMonth - 1];
    return '${h.hDay} $month ${h.hYear} AH';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final daytime = _isDaytime(provider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // ── Background: night blue gradient (always visible) ──────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A1F40), AppColors.primaryDark],
                  stops: [0.0, 0.55],
                ),
              ),
            ),
          ),

          // ── Background: warm amber overlay (fades in during daytime) ──────
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: daytime ? 1.0 : 0.0,
              duration: const Duration(seconds: 2),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2A1608), AppColors.primaryDark],
                    stops: [0.0, 0.55],
                  ),
                ),
              ),
            ),
          ),

          // ── Islamic geometric star pattern (top header region) ────────────
          Positioned(
            top: 0, left: 0, right: 0, height: 200,
            child: Opacity(
              opacity: 0.045,
              child: CustomPaint(painter: _GeometricPatternPainter()),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: switch (provider.status) {
              AppStatus.loading => _buildShimmer(),
              _ => _buildContent(context, provider),
            },
          ),
        ],
      ),
    );
  }

  // ── Shimmer loading skeleton ─────────────────────────────────────────────

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBg,
      highlightColor: AppColors.primaryLight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar skeleton
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Container(width: 140, height: 16,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 6),
                    Container(width: 100, height: 11,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Countdown circle skeleton
            Center(
              child: Container(
                width: 210, height: 210,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 24),
            // Next prayer banner skeleton
            Container(
              height: 52,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 24),
            // Section label skeleton
            Container(width: 100, height: 10,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 12),
            // Prayer row skeletons
            for (int i = 0; i < 6; i++) ...[
              Container(
                height: 60,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Main content ─────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, AppProvider provider) {
    final today = provider.todayTimes;

    return CustomScrollView(
      slivers: [
        // App bar (transparent so gradient shows through)
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            children: [
              Text(
                provider.city,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _hijriDateString(),
                style: TextStyle(
                  color: AppColors.gold.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (provider.locationError != null)
                Text(
                  'Using cached location',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 10),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location, color: AppColors.textSecondary),
              onPressed: () => provider.initialize(),
              tooltip: 'Refresh location',
            ),
          ],
        ),

        // High-latitude warning
        if (provider.lat.abs() > 60.0)
          SliverToBoxAdapter(child: _HighLatWarning(lat: provider.lat)),

        // Countdown — wrapped in a glass card with subtle pattern behind it
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: RepaintBoundary(child: const CountdownTimer()),
            ),
          ),
        ),

        // Next prayer banner (glass)
        if (today != null)
          SliverToBoxAdapter(
            child: _NextPrayerBanner(provider: provider),
          ),

        // Ramadan countdown (hidden during Ramadan)
        const SliverToBoxAdapter(child: RamadanCountdownCard()),

        // Ayah of the Day
        const SliverToBoxAdapter(child: AyahCard()),

        // Dua of the Day
        const SliverToBoxAdapter(child: DuaDayCard()),

        // Prayer tracker + streak
        if (provider.prayerTimerEnabled)
          SliverToBoxAdapter(
            child: ValueListenableBuilder<Box<PrayerLogModel>>(
              valueListenable: PrayerLogService.listenable,
              builder: (context, box, _) {
                final log = box.get(PrayerLogService.todayKey) ??
                    PrayerLogModel.empty(PrayerLogService.todayKey);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TODAY'S PRAYERS",
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      PrayerTrackerGrid(dayLog: log),
                      const SizedBox(height: 12),
                      const StreakWidget(),
                    ],
                  ),
                );
              },
            ),
          ),

        // Divider with "PRAYER TIMES" label
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.primaryLight)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'PRAYER TIMES',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.primaryLight)),
              ],
            ),
          ),
        ),

        // Prayer list
        if (today != null)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final names = AppConstants.prayerNames;
                final times = today.allTimes;
                final now = DateTime.now();
                final next = today.nextPrayer(now);

                final name = names[index];
                final time = times[index];
                final isNext = next?.key == name;
                final isPassed = time.isBefore(now);
                final isFard = name != 'Sunrise';

                return PrayerTimeCard(
                  name: name,
                  time: provider.formatTime(time),
                  icon: prayerIcon(name),
                  isNext: isNext,
                  isPassed: isPassed,
                  tappable: isFard && provider.prayerTimerEnabled,
                  onTap: () => _openPrayerTimer(context, name),
                );
              },
              childCount: AppConstants.prayerNames.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _openPrayerTimer(BuildContext context, String name) {
    final fardIndex = AppConstants.fardNames.indexOf(name);
    if (fardIndex < 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrayerTimerScreen(
          prayerName: name,
          fardIndex: fardIndex,
        ),
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _HighLatWarning extends StatelessWidget {
  final double lat;
  const _HighLatWarning({required this.lat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Extreme latitude (${lat.toStringAsFixed(1)}°). '
              'Prayer times may be estimated for your region.',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPrayerBanner extends StatelessWidget {
  final AppProvider provider;
  const _NextPrayerBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final today = provider.todayTimes;
    if (today == null) return const SizedBox.shrink();

    final next = today.nextPrayer(DateTime.now());
    if (next == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        tintColor: AppColors.gold.withValues(alpha: 0.10),
        borderColor: AppColors.gold.withValues(alpha: 0.35),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                color: AppColors.gold, size: 18),
            const SizedBox(width: 10),
            Text(
              'Next: ${next.key}',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              provider.formatTime(next.value),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiles an Islamic 8-pointed star pattern at low opacity.
class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    const spacing = 52.0;
    const outerR = 13.0;
    const innerR = outerR * 0.42;

    final cols = (size.width / spacing).ceil() + 2;
    final rows = (size.height / spacing).ceil() + 2;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cx = col * spacing + (row.isOdd ? spacing / 2 : 0);
        final cy = row * spacing;
        _drawStar(canvas, paint, Offset(cx, cy), outerR, innerR);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double outerR, double innerR) {
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
