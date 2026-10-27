import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import 'ui.dart';

/// Courbe d'évolution d'une mesure, avec ses valeurs extrêmes et ses dates.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.title,
    required this.points,
    required this.format,
    required this.formatChange,
  });

  final String title;

  /// Mesures triées par date.
  final List<(DateTime, double)> points;

  /// Libellé d'une valeur (axe) et de l'écart entre la première et la dernière.
  final String Function(double value) format;
  final String Function(double change) formatChange;

  @override
  Widget build(BuildContext context) {
    final values = points.map((point) => point.$2);
    final high = values.reduce((a, b) => a > b ? a : b);
    final low = values.reduce((a, b) => a < b ? a : b);
    final change = points.last.$2 - points.first.$2;
    return AppCard(
      radius: 16,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Eyebrow(title, color: AppColors.label, spacingEm: .18)),
              Text(
                formatChange(change),
                style: AppText.mono(size: 12, weight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: CustomPaint(painter: _TrendPainter(points))),
                SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(format(high), style: AppText.mono(size: 10, color: AppColors.dim)),
                    Text(format(low), style: AppText.mono(size: 10, color: AppColors.dim)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (date, _) in [points.first, points.last])
                Text(FrDate.abbrevDay(date), style: AppText.mono(size: 9, color: AppColors.dim)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Courbe placée selon les dates, avec la tendance en pointillés et un point par mesure.
class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.points);

  final List<(DateTime, double)> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (final fraction in [.09, .5, .91]) {
      final y = size.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final values = points.map((point) => point.$2);
    final high = values.reduce((a, b) => a > b ? a : b);
    final low = values.reduce((a, b) => a < b ? a : b);
    final range = high - low < .5 ? .5 : high - low;
    final start = points.first.$1;
    final days = points.last.$1.difference(start).inDays;
    final offsets = [
      for (final (date, value) in points)
        Offset(
          days == 0 ? size.width / 2 : date.difference(start).inDays / days * size.width,
          size.height * (.09 + (high - value) / range * .82),
        ),
    ];

    final trend = Path()
      ..moveTo(offsets.first.dx, offsets.first.dy)
      ..lineTo(offsets.last.dx, offsets.last.dy);
    final dashed = Paint()
      ..color = AppColors.dimmer
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final metric in trend.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), dashed);
        distance += 8;
      }
    }

    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      line.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.text
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    final dot = Paint()..color = AppColors.text;
    for (final offset in offsets) {
      canvas.drawCircle(offset, 3, dot);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.points != points;
}
