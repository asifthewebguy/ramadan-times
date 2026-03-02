import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Animated compass dial that rotates to show Qibla direction.
///
/// [deviceHeading] is the current compass bearing from North (degrees).
/// [qiblaDirection] is the Qibla bearing from North (degrees).
class CompassWidget extends StatelessWidget {
  final double deviceHeading;
  final double qiblaDirection;
  final double accuracy; // 0.0–1.0

  const CompassWidget({
    super.key,
    required this.deviceHeading,
    required this.qiblaDirection,
    required this.accuracy,
  });

  bool get _isAligned {
    final diff = ((qiblaDirection - deviceHeading) % 360).abs();
    final normalised = diff > 180 ? 360 - diff : diff;
    return normalised <= 3.0;
  }

  @override
  Widget build(BuildContext context) {
    // The needle should rotate so that Qibla faces up.
    // Rotate the dial by -(deviceHeading) so North stays relative to device.
    final dialRotation = -deviceHeading * math.pi / 180;
    // The Qibla arrow is drawn at qiblaDirection on the dial.
    final qiblaRotation = qiblaDirection * math.pi / 180;

    final arrowColor = _isAligned ? AppColors.qiblaGreen : AppColors.gold;

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
                color: _isAligned
                    ? AppColors.qiblaGreen.withValues(alpha: 0.6)
                    : AppColors.primaryLight,
                width: 2,
              ),
              color: AppColors.cardBg,
            ),
          ),

          // Rotating compass dial (cardinal directions)
          Transform.rotate(
            angle: dialRotation,
            child: CustomPaint(
              size: const Size(240, 240),
              painter: _DialPainter(),
            ),
          ),

          // Qibla direction arrow (rotates with device AND dial)
          Transform.rotate(
            angle: dialRotation + qiblaRotation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Arrow pointing up (toward Qibla)
                Icon(
                  Icons.navigation,
                  color: arrowColor,
                  size: 48,
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),

          // Centre dot + Kaaba icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryMid,
              border: Border.all(
                color: _isAligned ? AppColors.qiblaGreen : AppColors.gold,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.mosque,
              color: _isAligned ? AppColors.qiblaGreen : AppColors.gold,
              size: 24,
            ),
          ),

          // Accuracy warning overlay
          if (accuracy < 0.5)
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
  }
}

/// Paints the compass rose: N/S/E/W labels and tick marks.
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

    // Draw 72 ticks (every 5 degrees)
    for (int i = 0; i < 72; i++) {
      final angle = i * 5 * math.pi / 180;
      final isMajor = i % 9 == 0; // every 45°
      final tickLen = isMajor ? 14.0 : 7.0;
      final paint = isMajor ? majorTickPaint : tickPaint;
      final outer = center + Offset(math.cos(angle - math.pi / 2), math.sin(angle - math.pi / 2)) * radius;
      final inner = center + Offset(math.cos(angle - math.pi / 2), math.sin(angle - math.pi / 2)) * (radius - tickLen);
      canvas.drawLine(inner, outer, paint);
    }

    // Cardinal labels
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
