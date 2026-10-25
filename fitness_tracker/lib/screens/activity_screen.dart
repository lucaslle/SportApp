import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ui.dart';

const List<double> _elevation = [30, 42, 58, 70, 62, 48, 55, 72, 66, 44, 30, 22];

/// Écran 08 — Détail d'une sortie GPS.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScroll(
      children: [
        const BackLink('HISTORIQUE'),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              color: AppColors.cardDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: CustomPaint(
              painter: const _StripePainter(),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CARTE + TRACE GPS',
                      style: AppText.mono(size: 11, color: const Color(0xFF6F6F6F), letterSpacingEm: .18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'importée depuis Strava',
                      style: AppText.mono(size: 9, color: const Color(0xFF525252), letterSpacingEm: .1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 10),
          child: Row(
            children: [TagPill('TRAIL'), SizedBox(width: 8), TagPill('SORTIE LONGUE')],
          ),
        ),
        Text('Trail des Crêtes', style: AppText.screenTitle()),
        const SizedBox(height: 5),
        Text(
          'Dim. 13 sept. · 8h04 · 14 °C · vent 12 km/h',
          style: AppText.sans(size: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                for (final (label, value) in const [
                  ('DIST', '18,4'),
                  ('TEMPS', '1h47'),
                  ('ALLURE', '5′49'),
                  ('D+', '612'),
                ])
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                      color: AppColors.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(label, size: 8, spacingEm: .1),
                          const SizedBox(height: 5),
                          Text(value, style: AppText.mono(size: 15, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          radius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('PROFIL ALTIMÉTRIQUE', color: AppColors.label, spacingEm: .18),
              const SizedBox(height: 12),
              const SizedBox(
                height: 84,
                width: double.infinity,
                child: CustomPaint(painter: _ElevationPainter(_elevation)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final label in const ['0 km', '9 km', '18,4 km'])
                    Text(label, style: AppText.mono(size: 9, color: AppColors.dim)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const TileGrid(
          children: [
            StatTile(label: 'FC MOY', value: '156', valueSize: 17),
            StatTile(label: 'CADENCE', value: '174', valueSize: 17),
            StatTile(label: 'CHARGE', value: '142', valueSize: 17),
          ],
        ),
        const SectionLabel('SPLITS', top: 20, bottom: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Row(
            children: [
              SizedBox(width: 34, child: Eyebrow('KM', size: 9, color: AppColors.dim, spacingEm: .1)),
              Expanded(child: Eyebrow('ALLURE', size: 9, color: AppColors.dim, spacingEm: .1)),
              SizedBox(width: 52, child: Eyebrow('D+', size: 9, color: AppColors.dim, spacingEm: .1, align: TextAlign.right)),
              SizedBox(width: 44, child: Eyebrow('FC', size: 9, color: AppColors.dim, spacingEm: .1, align: TextAlign.right)),
            ],
          ),
        ),
        for (final (km, pace, elev, hr, fraction) in const [
          ('1', '5′12', '+18 m', '148', .62),
          ('2', '5′34', '+62 m', '156', .74),
          ('3', '6′21', '+118 m', '168', .96),
          ('4', '5′02', '−74 m', '152', .54),
          ('5', '5′44', '+54 m', '159', .78),
          ('6', '6′38', '+142 m', '171', 1.0),
        ])
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                SizedBox(width: 34, child: Text(km, style: AppText.mono(size: 12, color: AppColors.label))),
                SizedBox(width: 46, child: Text(pace, style: AppText.mono(size: 12, weight: FontWeight.w700))),
                const SizedBox(width: 10),
                Expanded(
                  child: ProgressBar(fraction: fraction, height: 5, color: const Color(0xFFE8E8E8)),
                ),
                SizedBox(
                  width: 52,
                  child: Text(elev, textAlign: TextAlign.right, style: AppText.mono(size: 12, color: AppColors.label)),
                ),
                SizedBox(width: 44, child: Text(hr, textAlign: TextAlign.right, style: AppText.mono(size: 12))),
              ],
            ),
          ),
      ],
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF191919)
      ..strokeWidth = 3;
    final diagonal = size.width + size.height;
    for (var offset = -size.height; offset < diagonal; offset += 11.3) {
      canvas.drawLine(Offset(offset, 0), Offset(offset + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => false;
}

class _ElevationPainter extends CustomPainter {
  const _ElevationPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(i * size.width / (values.length - 1), size.height * (1 - values[i] * .9 / 80)),
    ];
    final area = Path()..moveTo(0, size.height);
    for (final point in points) {
      area.lineTo(point.dx, point.dy);
    }
    area
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = AppColors.blockLow);

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.text
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_ElevationPainter old) => old.values != values;
}
