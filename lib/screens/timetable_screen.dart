import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/prayer_time_model.dart';
import '../utils/theme.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final ScrollController _verticalScroll = ScrollController();
  bool _localUse24h = false;

  static const _colWidths = [40.0, 52.0, 66.0, 70.0, 66.0, 66.0, 72.0, 66.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _verticalScroll.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    final now = DateTime.now();
    final rowHeight = 44.0;
    final headerHeight = 48.0;
    final targetOffset = headerHeight + (now.day - 1) * rowHeight - 80;
    if (_verticalScroll.hasClients) {
      _verticalScroll.animateTo(
        targetOffset.clamp(0, _verticalScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final use24h = _localUse24h != provider.use24h ? provider.use24h : _localUse24h;
    _localUse24h = use24h;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Monthly Timetable'),
            Text(
              provider.city,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => setState(() => _localUse24h = !_localUse24h),
              child: Text(
                _localUse24h ? '12H' : '24H',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: provider.monthlyTimes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : _buildTable(context, provider),
    );
  }

  Widget _buildTable(BuildContext context, AppProvider provider) {
    final today = DateTime.now().day;
    final month = DateTime.now();
    final monthName = _monthName(month.month);
    final year = month.year;

    return Column(
      children: [
        // Month/year header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: AppColors.primaryMid,
          child: Center(
            child: Text(
              '$monthName $year',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // Table (horizontal + vertical scroll)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _colWidths.fold<double>(0.0, (a, b) => a + b),
              child: Column(
                children: [
                  // Column headers
                  _HeaderRow(),
                  // Data rows
                  Expanded(
                    child: ListView.builder(
                      controller: _verticalScroll,
                      itemCount: provider.monthlyTimes.length,
                      itemExtent: 44.0,
                      itemBuilder: (context, index) {
                        final dayTimes = provider.monthlyTimes[index];
                        final isToday = dayTimes.date.day == today;
                        return _DataRow(
                          dayTimes: dayTimes,
                          isToday: isToday,
                          use24h: _localUse24h,
                          formatTime: provider.formatTime,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }
}

class _HeaderRow extends StatelessWidget {
  static const _columns = ['Day', 'Date', 'Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const _widths = [40.0, 52.0, 66.0, 70.0, 66.0, 66.0, 72.0, 66.0];

  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppColors.primaryLight,
      child: Row(
        children: List.generate(_columns.length, (i) {
          return SizedBox(
            width: _widths[i],
            child: Center(
              child: Text(
                _columns[i],
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final PrayerTimeModel dayTimes;
  final bool isToday;
  final bool use24h;
  final String Function(DateTime) formatTime;

  static const _widths = [40.0, 52.0, 66.0, 70.0, 66.0, 66.0, 72.0, 66.0];
  static const _dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const _DataRow({
    required this.dayTimes,
    required this.isToday,
    required this.use24h,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isToday
        ? AppColors.gold.withValues(alpha: 0.12)
        : (dayTimes.date.day.isOdd ? AppColors.cardBg : AppColors.primaryDark);

    final dayOfWeek = dayTimes.date.weekday; // 1=Mon, 7=Sun
    final isFriday = dayOfWeek == 5;
    final textColor = isToday ? AppColors.gold : AppColors.textPrimary;
    final fridayColor = isFriday ? const Color(0xFF2ECC71) : textColor;

    final times = [
      formatTime(dayTimes.fajr),
      formatTime(dayTimes.sunrise),
      formatTime(dayTimes.dhuhr),
      formatTime(dayTimes.asr),
      formatTime(dayTimes.maghrib),
      formatTime(dayTimes.isha),
    ];

    return Container(
      color: bg,
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: _widths[0],
            child: Center(
              child: Text(
                _dayNames[dayOfWeek],
                style: TextStyle(
                  color: fridayColor,
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
          // Date
          SizedBox(
            width: _widths[1],
            child: Center(
              child: isToday
                  ? Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${dayTimes.date.day}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      '${dayTimes.date.day}',
                      style: TextStyle(
                        color: fridayColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          // Prayer times
          ...List.generate(6, (i) {
            return SizedBox(
              width: _widths[i + 2],
              child: Center(
                child: Text(
                  times[i],
                  style: TextStyle(
                    color: isToday ? AppColors.gold : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
