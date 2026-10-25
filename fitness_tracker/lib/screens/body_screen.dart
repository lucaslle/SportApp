import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ui.dart';

const List<double> _weights = [70.2, 70.0, 69.8, 69.9, 69.4, 69.5, 69.1, 68.9, 69.0, 68.7, 68.5, 68.4];

/// Écran 06 — Poids & composition.
class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScroll(
      children: [
        const Eyebrow('CORPS'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '68,4',
              style: AppText.mono(size: 46, weight: FontWeight.w700, letterSpacingEm: -.03, height: 1),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('kg', style: AppText.mono(size: 15, color: AppColors.muted)),
            ),
            const SizedBox(width: 12),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: TagPill(
                '−0,6 · 30j',
                size: 13,
                color: AppColors.text,
                spacingEm: 0,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          radius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Eyebrow('TENDANCE 12 SEMAINES', color: AppColors.label, spacingEm: .18),
                  Text('kg', style: AppText.mono(size: 10, color: AppColors.mutedDark)),
                ],
              ),
              const SizedBox(height: 12),
              const SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(painter: _WeightChartPainter(_weights)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final label in const ['S25', 'S31', 'S37'])
                    Text(label, style: AppText.mono(size: 9, color: AppColors.dim)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const TileGrid(
          children: [
            StatTile(label: 'M. GRASSE', value: '12,4 %', sub: '−0,8', valueSize: 18),
            StatTile(label: 'M. MUSCLE', value: '34,1 kg', sub: '+0,3', valueSize: 18),
            StatTile(label: 'EAU', value: '61 %', sub: 'stable', valueSize: 18),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Balance connectée', style: AppText.sans(size: 14, weight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'Synchro il y a 2 h · pesée du matin',
                      style: AppText.mono(size: 10, color: AppColors.mutedDark),
                    ),
                  ],
                ),
              ),
              const AppToggle(value: true),
            ],
          ),
        ),
        const SectionLabel('DERNIÈRES PESÉES', top: 20),
        for (final (date, fat, kg) in const [
          ('Lun 14 sept.', '12,4 %', '68,4 kg'),
          ('Dim 13 sept.', '12,5 %', '68,6 kg'),
          ('Sam 12 sept.', '12,6 %', '68,5 kg'),
          ('Ven 11 sept.', '12,7 %', '68,9 kg'),
          ('Jeu 10 sept.', '12,6 %', '68,8 kg'),
        ])
          ListRow(
            leading: Text(date, style: AppText.mono(size: 12, color: AppColors.label)),
            trailing: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(fat, style: AppText.mono(size: 11, color: AppColors.mutedDark)),
                const SizedBox(width: 16),
                Text(kg, style: AppText.mono(size: 14, weight: FontWeight.w700)),
              ],
            ),
          ),
        const SizedBox(height: 14),
        DashedBox(
          padding: const EdgeInsets.all(14),
          child: Center(
            child: Text('Saisir une pesée manuelle', style: AppText.sans(size: 14, weight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (final fraction in const [.09, .5, .91]) {
      final y = size.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    double yOf(double value) => size.height * (.09 + (70.5 - value) / 2.5 * .82);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(i * size.width / (values.length - 1), yOf(values[i])),
    ];

    final trend = Path()
      ..moveTo(points.first.dx, points.first.dy)
      ..lineTo(points.last.dx, points.last.dy);
    final dashed = Paint()
      ..color = const Color(0xFF5A5A5A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final metric in trend.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), dashed);
        distance += 8;
      }
    }

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.text
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_WeightChartPainter old) => old.values != values;
}
