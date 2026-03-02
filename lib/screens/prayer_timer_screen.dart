import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/prayer_log_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

enum _TimerState { idle, running, paused, done }

class PrayerTimerScreen extends StatefulWidget {
  final String prayerName;
  final int fardIndex;

  const PrayerTimerScreen({
    super.key,
    required this.prayerName,
    required this.fardIndex,
  });

  @override
  State<PrayerTimerScreen> createState() => _PrayerTimerScreenState();
}

class _PrayerTimerScreenState extends State<PrayerTimerScreen>
    with TickerProviderStateMixin {
  _TimerState _state = _TimerState.idle;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final AnimationController _checkController;
  late final Animation<double> _checkAnim;

  List<int> get _suggested =>
      AppConstants.suggestedDurations[widget.prayerName] ?? [5 * 60, 8 * 60];

  int get _maxSecs => _suggested[1];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkAnim = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  // ── Controls ─────────────────────────────────────────────────────────────────

  void _start() {
    setState(() => _state = _TimerState.running);
    _pulseController.repeat(reverse: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _pause() {
    _ticker?.cancel();
    _pulseController.stop();
    _pulseController.value = 0;
    setState(() => _state = _TimerState.paused);
  }

  Future<void> _complete() async {
    _ticker?.cancel();
    _pulseController.stop();
    HapticFeedback.mediumImpact();
    await PrayerLogService.logPrayer(
      dateKey: PrayerLogService.todayKey,
      fardIndex: widget.fardIndex,
      durationSeconds: _elapsed.inSeconds,
    );
    setState(() => _state = _TimerState.done);
    _checkController.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  Future<void> _markPrayed() async {
    HapticFeedback.lightImpact();
    await PrayerLogService.logPrayer(
      dateKey: PrayerLogService.todayKey,
      fardIndex: widget.fardIndex,
      durationSeconds: 0,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String get _elapsedLabel {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress =>
      _maxSecs > 0 ? (_elapsed.inSeconds / _maxSecs).clamp(0.0, 1.0) : 0.0;

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text('${widget.prayerName} Timer'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: _state == _TimerState.done ? _buildDone() : _buildTimer(),
      ),
    );
  }

  Widget _buildDone() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _checkAnim,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.qiblaGreen.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.qiblaGreen, width: 2),
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.qiblaGreen,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Prayer Logged!',
            style: TextStyle(
              color: AppColors.qiblaGreen,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Duration: $_elapsedLabel',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final alreadyLogged = PrayerLogService.todayLog.completed[widget.fardIndex];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Prayer name
            Text(
              widget.prayerName,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Suggested: ${_suggested[0] ~/ 60}–${_suggested[1] ~/ 60} min',
              style: const TextStyle(color: AppColors.textDim, fontSize: 13),
            ),

            const SizedBox(height: 40),

            // Pulsing timer dial
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => Transform.scale(
                scale: _state == _TimerState.running ? _pulseAnim.value : 1.0,
                child: child,
              ),
              child: _TimerDial(
                elapsed: _elapsedLabel,
                progress: _progress,
              ),
            ),

            const SizedBox(height: 48),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_state == _TimerState.idle) ...[
                  _CircleButton(
                    icon: Icons.play_arrow,
                    color: AppColors.gold,
                    onTap: _start,
                    label: 'Start',
                  ),
                ] else if (_state == _TimerState.running) ...[
                  _CircleButton(
                    icon: Icons.pause,
                    color: AppColors.textSecondary,
                    onTap: _pause,
                    label: 'Pause',
                  ),
                  const SizedBox(width: 24),
                  _CircleButton(
                    icon: Icons.check,
                    color: AppColors.qiblaGreen,
                    onTap: _complete,
                    label: 'Done',
                  ),
                ] else if (_state == _TimerState.paused) ...[
                  _CircleButton(
                    icon: Icons.play_arrow,
                    color: AppColors.gold,
                    onTap: _start,
                    label: 'Resume',
                  ),
                  const SizedBox(width: 24),
                  _CircleButton(
                    icon: Icons.check,
                    color: AppColors.qiblaGreen,
                    onTap: _complete,
                    label: 'Done',
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            // Mark as prayed / already logged
            if (alreadyLogged)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.qiblaGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.qiblaGreen.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Already logged today',
                  style: TextStyle(color: AppColors.qiblaGreen, fontSize: 13),
                ),
              )
            else
              TextButton(
                onPressed: _markPrayed,
                child: const Text(
                  'Mark as Prayed (no timer)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TimerDial extends StatelessWidget {
  final String elapsed;
  final double progress;

  const _TimerDial({required this.elapsed, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 10,
            backgroundColor: AppColors.primaryLight,
            color: AppColors.gold,
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          elapsed,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 42,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
