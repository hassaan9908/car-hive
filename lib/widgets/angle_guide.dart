import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:carhive/models/car_360_set.dart';

/// A compass-like widget showing 16 angle positions for 360° capture
class AngleGuide extends StatelessWidget {
  /// Current angle index being captured (0-15)
  final int currentAngleIndex;

  /// List of captured angle indices
  final List<bool> capturedAngles;

  /// Size of the widget
  final double size;

  /// Callback when an angle is tapped
  final Function(int)? onAngleTap;

  const AngleGuide({
    super.key,
    required this.currentAngleIndex,
    required this.capturedAngles,
    this.size = 200,
    this.onAngleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AngleGuidePainter(
          currentAngleIndex: currentAngleIndex,
          capturedAngles: capturedAngles,
          primaryColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          capturedColor: Colors.green,
          currentColor: theme.colorScheme.secondary,
          uncapturedColor: theme.colorScheme.outline,
        ),
        child: Stack(
          children: [
            // Center car icon
            Center(
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_car,
                  size: size * 0.15,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            // Angle markers (tappable)
            ...List.generate(16, (index) {
              final angle = Car360Set.getAngleDegrees(index);
              final radians = (angle - 90) * math.pi / 180;
              final radius = size * 0.38;
              final x = size / 2 + radius * math.cos(radians);
              final y = size / 2 + radius * math.sin(radians);

              return Positioned(
                left: x - 12,
                top: y - 12,
                child: GestureDetector(
                  onTap: onAngleTap != null ? () => onAngleTap!(index) : null,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentAngleIndex
                          ? theme.colorScheme.secondary
                          : capturedAngles[index]
                              ? Colors.green
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                      border: Border.all(
                        color: index == currentAngleIndex
                            ? theme.colorScheme.secondary
                            : capturedAngles[index]
                                ? Colors.green
                                : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: capturedAngles[index]
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: index == currentAngleIndex
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the angle guide background
class _AngleGuidePainter extends CustomPainter {
  final int currentAngleIndex;
  final List<bool> capturedAngles;
  final Color primaryColor;
  final Color backgroundColor;
  final Color capturedColor;
  final Color currentColor;
  final Color uncapturedColor;

  _AngleGuidePainter({
    required this.currentAngleIndex,
    required this.capturedAngles,
    required this.primaryColor,
    required this.backgroundColor,
    required this.capturedColor,
    required this.currentColor,
    required this.uncapturedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    // Draw outer circle
    final outerPaint = Paint()
      ..color = uncapturedColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outerPaint);

    // Draw inner circle
    final innerPaint = Paint()
      ..color = uncapturedColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.7, innerPaint);

    // Draw compass lines
    final linePaint = Paint()
      ..color = uncapturedColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw 16 guide lines
    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5 - 90) * math.pi / 180;
      final innerRadius = radius * 0.5;
      final outerRadius = radius * 0.9;

      final start = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      canvas.drawLine(start, end, linePaint);
    }

    // Draw current angle indicator (arc)
    if (currentAngleIndex >= 0 && currentAngleIndex < 16) {
      final arcPaint = Paint()
        ..color = currentColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      final startAngle = (currentAngleIndex * 22.5 - 90 - 11.25) * math.pi / 180;
      const sweepAngle = 22.5 * math.pi / 180;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.85),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // Draw cardinal direction labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final labels = ['N', 'E', 'S', 'W'];
    final labelAngles = [-90.0, 0.0, 90.0, 180.0];

    for (int i = 0; i < 4; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: uncapturedColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      final angle = labelAngles[i] * math.pi / 180;
      final labelRadius = radius + 15;
      final x = center.dx + labelRadius * math.cos(angle) - textPainter.width / 2;
      final y = center.dy + labelRadius * math.sin(angle) - textPainter.height / 2;

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _AngleGuidePainter oldDelegate) {
    return currentAngleIndex != oldDelegate.currentAngleIndex ||
        capturedAngles != oldDelegate.capturedAngles;
  }
}

/// A linear progress indicator showing capture progress
class CaptureProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<bool> capturedAngles;

  const CaptureProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.capturedAngles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capturedCount = capturedAngles.where((c) => c).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$capturedCount/$totalSteps captured',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: capturedCount / totalSteps,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              capturedCount == totalSteps ? Colors.green : theme.colorScheme.primary,
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final isCaptured = capturedAngles[index];
            final isCurrent = index == currentStep;

            return Container(
              width: isCurrent ? 12 : 8,
              height: isCurrent ? 12 : 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCaptured
                    ? Colors.green
                    : isCurrent
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                border: isCurrent
                    ? Border.all(
                        color: theme.colorScheme.secondary,
                        width: 2,
                      )
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

