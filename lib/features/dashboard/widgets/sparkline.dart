import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

import 'dashboard_metrics.dart';

/// The seven-day revenue trace on the Last 7 days tile.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.series});

  final List<Decimal> series;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DashboardMetrics.sparkHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: [for (final value in series) value.toDouble()],
          color: context.colors.inkPrimary,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final lowest = values.reduce((a, b) => a < b ? a : b);
    final highest = values.reduce((a, b) => a > b ? a : b);
    final span = highest - lowest;

    final step = size.width / (values.length - 1);
    // A flat week has no range to scale against; drawing it mid-height keeps
    // the trace honest instead of dividing by zero.
    final points = [
      for (var index = 0; index < values.length; index++)
        Offset(
          index * step,
          span == 0
              ? size.height / 2
              : size.height - ((values[index] - lowest) / span) * size.height,
        ),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = DashboardMetrics.sparkStroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      points.last,
      DashboardMetrics.sparkDotRadius,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
