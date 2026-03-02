import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: SafeArea(
        child: switch (provider.status) {
          AppStatus.loading => const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          _ => _buildContent(context, provider),
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppProvider provider) {
    final today = provider.todayTimes;

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.primaryDark,
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
              if (provider.locationError != null)
                Text(
                  'Using cached location',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
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

        // High-latitude warning (> 60°N or < 60°S)
        if (provider.lat.abs() > 60.0)
          SliverToBoxAdapter(child: _HighLatWarning(lat: provider.lat)),

        // Countdown (RepaintBoundary isolates repaints from the rest of the tree)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: RepaintBoundary(child: CountdownTimer()),
          ),
        ),

        // Next prayer banner
        if (today != null)
          SliverToBoxAdapter(
            child: _NextPrayerBanner(provider: provider),
          ),

        // Prayer tracker + streak (when feature enabled)
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

        // Divider
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
                // Sunrise is informational only; Fard prayers are tappable
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
          const Icon(Icons.warning_amber_outlined,
              color: Colors.orange, size: 18),
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
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
    );
  }
}
