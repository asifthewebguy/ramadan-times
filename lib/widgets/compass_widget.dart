import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Compass dial with smoothly animated needle.
///
/// [deviceHeading] is the raw sensor bearing (degrees, updated externally).
/// The widget interpolates each incoming heading update with easeOut so the
/// needle swings fluidly rather than snapping.
class CompassWidget extends StatefulWidget {
  final double deviceHeading;
  final double qiblaDirection;
  final double accuracy; // 0.0–1.0

  const CompassWidget({
    super.key,
    required this.deviceHeading,
    required this.qiblaDirection,
    required this.accuracy,
  });

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headingAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    // Initialise at the first reported heading (no animation on first frame)
    _headingAnim = Tween<double>(
      begin: widget.deviceHeading,
      end: widget.deviceHeading,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(CompassWidget old) {
    super.didUpdateWidget(old);
    if (old.deviceHeading != widget.deviceHeading) {
      _animateTo(widget.deviceHeading);
    }
  }

  /// Animates to [newHeading] via the shortest arc (handles 355° → 10° etc.).
  void _animateTo(double newHeading) {
    final current = _headingAnim.value;

    // Shortest-path delta: result is in (-180, 180]
    var diff = (newHeading - current % 360) % 360;
    if (diff > 180) diff -= 360;
    final target = current + diff;

    _headingAnim = Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _aligned(double heading) {
    final diff = ((widget.qiblaDirection - heading) % 360).abs();
    final normalised = diff > 180 ? 360 - diff : diff;
    return normalised <= 3.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _headingAnim,
      builder: (context, _) {
        final heading = _headingAnim.value;
        final isAligned = _aligned(heading);
        final arrowColor = isAligned ? AppColors.qiblaGreen : AppColors.gold;

        final dialAngle = -heading * math.pi / 180;
        final qiblaAngle = widget.qiblaDirection * math.pi / 180;

        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAligned
                        ? AppColors.qiblaGreen.withValues(alpha: 0.6)
                        : AppColors.primaryLight,
                    width: 2,
                  ),
                  color: AppColors.cardBg,
                ),
              ),

              // Rotating compass dial
              Transform.rotate(
                angle: dialAngle,
                child: CustomPaint(
                  size: const Size(240, 240),
                  painter: _DialPainter(),
                ),
              ),

              // Qibla arrow
              Transform.rotate(
                angle: dialAngle + qiblaAngle,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation, color: arrowColor, size: 48),
                    const SizedBox(height: 90),
                  ],
                ),
              ),

              // Centre: Kaaba icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryMid,
                  border: Border.all(
                    color: isAligned ? AppColors.qiblaGreen : AppColors.gold,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.mosque,
                  color: isAligned ? AppColors.qiblaGreen : AppColors.gold,
                  size: 24,
                ),
              ),

              // Low-accuracy warning badge
              if (widget.accuracy < 0.5)
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'Low accuracy — move away from electronics',
                      style: TextStyle(color: Colors.orange, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Paints compass rose tick marks and N/S/E/W labels.
class _DialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = AppColors.textDim
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 72; i++) {
      final angle = i * 5 * math.pi / 180;
      final isMajor = i % 9 == 0; // every 45°
      final tickLen = isMajor ? 14.0 : 7.0;
      final paint = isMajor ? majorTickPaint : tickPaint;
      final dir = Offset(math.cos(angle - math.pi / 2), math.sin(angle - math.pi / 2));
      canvas.drawLine(center + dir * (radius - tickLen), center + dir * radius, paint);
    }

    _drawLabel(canvas, center, radius - 28, 0, 'N', AppColors.gold, 14, FontWeight.w700);
    _drawLabel(canvas, center, radius - 28, math.pi / 2, 'E', AppColors.textSecondary, 12, FontWeight.w500);
    _drawLabel(canvas, center, radius - 28, math.pi, 'S', AppColors.textSecondary, 12, FontWeight.w500);
    _drawLabel(canvas, center, radius - 28, -math.pi / 2, 'W', AppColors.textSecondary, 12, FontWeight.w500);
  }

  void _drawLabel(Canvas canvas, Offset center, double dist, double angle,
      String text, Color color, double fontSize, FontWeight weight) {
    final offset = center +
        Offset(math.cos(angle - math.pi / 2), math.sin(angle - math.pi / 2)) * dist;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
