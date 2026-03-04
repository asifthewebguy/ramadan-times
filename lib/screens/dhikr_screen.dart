import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../utils/theme.dart';

/// The three standard post-prayer dhikr, each recited 33 times.
const _kDhikr = [
  _DhikrItem(
    arabic: 'سُبْحَانَ ٱللَّه',
    transliteration: 'SubhanAllah',
    translation: 'Glory be to Allah',
  ),
  _DhikrItem(
    arabic: 'ٱلْحَمْدُ لِلَّه',
    transliteration: 'Alhamdulillah',
    translation: 'All praise is due to Allah',
  ),
  _DhikrItem(
    arabic: 'ٱللَّهُ أَكْبَر',
    transliteration: 'Allahu Akbar',
    translation: 'Allah is the Greatest',
  ),
];

class _DhikrItem {
  final String arabic;
  final String transliteration;
  final String translation;
  const _DhikrItem(
      {required this.arabic,
      required this.transliteration,
      required this.translation});
}

class DhikrScreen extends StatefulWidget {
  const DhikrScreen({super.key});

  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen>
    with TickerProviderStateMixin {
  static const int _target = 33;
  static const int _totalTarget = 99; // 3 × 33

  int _dhikrIndex = 0; // 0, 1, 2
  int _count = 0; // count within current dhikr (0–32)
  int _totalCount = 0; // grand total (0–99)
  bool _complete = false;

  late AnimationController _pulseController;
  late AnimationController _celebrateController;
  late Animation<double> _pulseAnim;
  late Animation<double> _celebrateAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _celebrateAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrateController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_complete) return;

    // Pulse animation feedback
    _pulseController.forward(from: 0).then((_) => _pulseController.reverse());

    // Haptic
    HapticFeedback.lightImpact();

    setState(() {
      _count++;
      _totalCount++;
    });

    if (_count >= _target) {
      if (_dhikrIndex < 2) {
        // Advance to next dhikr
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) {
            setState(() {
              _dhikrIndex++;
              _count = 0;
            });
          }
        });
      } else {
        // All 99 done
        HapticFeedback.heavyImpact();
        setState(() => _complete = true);
        _celebrateController.forward(from: 0);
      }
    }
  }

  void _reset() {
    setState(() {
      _dhikrIndex = 0;
      _count = 0;
      _totalCount = 0;
      _complete = false;
    });
    _celebrateController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final dhikr = _kDhikr[_dhikrIndex];
    final percent = _totalCount / _totalTarget;
    final ringColor = _complete ? AppColors.qiblaGreen : AppColors.gold;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Dhikr Counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Dhikr selector tabs ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: List.generate(_kDhikr.length, (i) {
                  final active = i == _dhikrIndex;
                  final done = i < _dhikrIndex || _complete;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!_complete) {
                          setState(() {
                            _dhikrIndex = i;
                            _count = i < _dhikrIndex ? _target : _count;
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.qiblaGreen.withValues(alpha: 0.15)
                              : active
                                  ? AppColors.gold.withValues(alpha: 0.15)
                                  : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: done
                                ? AppColors.qiblaGreen.withValues(alpha: 0.5)
                                : active
                                    ? AppColors.gold.withValues(alpha: 0.5)
                                    : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (done)
                              const Icon(Icons.check_circle,
                                  color: AppColors.qiblaGreen, size: 14)
                            else
                              Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: active
                                      ? AppColors.gold
                                      : AppColors.textDim,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              _kDhikr[i].transliteration,
                              style: TextStyle(
                                color: done
                                    ? AppColors.qiblaGreen
                                    : active
                                        ? AppColors.gold
                                        : AppColors.textDim,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),

            // ── Main tap circle ──────────────────────────────────────────
            _complete
                ? ScaleTransition(
                    scale: _celebrateAnim,
                    child: _CompleteBadge(onReset: _reset),
                  )
                : ScaleTransition(
                    scale: _pulseAnim,
                    child: GestureDetector(
                      onTap: _onTap,
                      child: CircularPercentIndicator(
                        radius: 130.0,
                        lineWidth: 10.0,
                        percent: percent.clamp(0.0, 1.0),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: ringColor,
                        backgroundColor: AppColors.primaryLight,
                        animation: false,
                        center: _TapCircleCenter(
                          dhikr: dhikr,
                          count: _count,
                          target: _target,
                          color: ringColor,
                        ),
                      ),
                    ),
                  ),

            const Spacer(),

            // ── Total progress footer ────────────────────────────────────
            if (!_complete)
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  children: [
                    Text(
                      '$_totalCount / $_totalTarget',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap anywhere on the circle to count',
                      style:
                          TextStyle(color: AppColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TapCircleCenter extends StatelessWidget {
  final _DhikrItem dhikr;
  final int count;
  final int target;
  final Color color;

  const _TapCircleCenter({
    required this.dhikr,
    required this.count,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardBg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Arabic text
          Text(
            dhikr.arabic,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            dhikr.transliteration,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          // Large count
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 52,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          Text(
            '/ $target',
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteBadge extends StatelessWidget {
  final VoidCallback onReset;
  const _CompleteBadge({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.qiblaGreen.withValues(alpha: 0.12),
            border: Border.all(
                color: AppColors.qiblaGreen.withValues(alpha: 0.5), width: 2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.qiblaGreen, size: 52),
              SizedBox(height: 8),
              Text(
                'Complete!',
                style: TextStyle(
                  color: AppColors.qiblaGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '99 dhikr done',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh, color: AppColors.gold, size: 18),
          label: const Text(
            'Start Again',
            style: TextStyle(color: AppColors.gold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
