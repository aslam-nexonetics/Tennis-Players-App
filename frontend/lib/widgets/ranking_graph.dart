import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:intl/intl.dart';

class RankingPoint {
  final int ranking;
  final DateTime date;

  RankingPoint({required this.ranking, required this.date});
}

class RankingGraph extends StatelessWidget {
  final List<RankingPoint> points;
  final Color color;

  const RankingGraph({
    super.key,
    required this.points,
    this.color = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 40),
      child: CustomPaint(painter: _GraphPainter(points, color)),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<RankingPoint> points;
  final Color color;

  _GraphPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

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

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final path = Path();
    final fillPath = Path();

    // In tennis, lower rank is better (higher on graph)
    final rankings = points.map((p) => p.ranking.toDouble()).toList();
    final minRank = rankings.reduce(math.min);
    final maxRank = rankings.reduce(math.max);
    final range = (maxRank - minRank).clamp(1.0, double.infinity);

    double xStep = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      // Normalize to 0.0 - 1.0 (inverted for rank)
      double normalized = 1.0 - ((points[i].ranking - minRank) / range);
      double x = i * xStep;
      double y = size.height *
          (1.0 - (normalized * 0.7 + 0.15)); // Center with padding

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

      // Draw Labels (Ranking value above point)
      textPainter.text = TextSpan(
        text: '#${points[i].ranking}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), y - 20));

      // Draw Year below
      textPainter.text = TextSpan(
        text: DateFormat('yy').format(points[i].date),
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height + 10),
      );
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()..color = color;
    final dotBgPaint = Paint()..color = Colors.white;
    for (int i = 0; i < points.length; i++) {
      double normalized = 1.0 - ((points[i].ranking - minRank) / range);
      double x = i * xStep;
      double y = size.height * (1.0 - (normalized * 0.7 + 0.15));

      canvas.drawCircle(Offset(x, y), 5, dotBgPaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
