import 'package:flutter/material.dart';
import 'dart:math' as math;

class RankingGraph extends StatelessWidget {
  final List<double> dataPoints;
  final Color color;

  const RankingGraph({
    super.key,
    required this.dataPoints,
    this.color = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: CustomPaint(painter: _GraphPainter(dataPoints, color)),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _GraphPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    // In tennis, lower rank is better (higher on graph)
    // We normalize the points: higher value in data = lower on chart
    final minVal = points.reduce(math.min);
    final maxVal = points.reduce(math.max);
    final range = (maxVal - minVal).clamp(1, double.infinity);

    double xStep = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      // Normalize to 0.0 - 1.0 (inverted for rank)
      double normalized = 1.0 - ((points[i] - minVal) / range);
      double x = i * xStep;
      double y = size.height * (1.0 - (normalized * 0.8 + 0.1)); // Padding 10%

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == points.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points
    final dotPaint = Paint()..color = color;
    final dotBgPaint = Paint()..color = Colors.white;
    for (int i = 0; i < points.length; i++) {
      double normalized = 1.0 - ((points[i] - minVal) / range);
      double x = i * xStep;
      double y = size.height * (1.0 - (normalized * 0.8 + 0.1));

      canvas.drawCircle(Offset(x, y), 5, dotBgPaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
