import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/connections_providers.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';

/// Écran 11 — Objectifs & records.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalRace = ref.watch(goalRaceProvider);
    final today = ref.watch(todayProvider);
    final raceDay = DateTime(2026, 10, 25);
    final days = FrDate.daysBetween(today, raceDay);
    final countdown = days > 0 ? 'J−$days' : days == 0 ? 'JOUR J' : 'J+${-days}';

    if (!ref.watch(demoDataProvider)) {
      return ScreenScroll(
        children: [
          BackLink('STATS'),
          ScreenHeader(eyebrow: 'OBJECTIFS', title: 'Course cible & records'),
          SizedBox(height: 18),
          EmptyState(
            title: 'Aucun objectif ni record',
            message: 'Vos records personnels apparaîtront ici',
          ),
        ],
      );
    }

    return ScreenScroll(
      children: [
        BackLink('STATS'),
        ScreenHeader(eyebrow: 'OBJECTIFS', title: 'Course cible & records'),
        SizedBox(height: 18),
        Container(
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'OBJECTIF PRINCIPAL',
                    style: AppText.mono(size: 10, color: AppColors.onLight, letterSpacingEm: .18),
                  ),
                  TagPill(countdown, size: 10, color: AppColors.onLight, borderColor: AppColors.onLight, spacingEm: 0),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  goalRace,
                  style: AppText.sans(size: 21, weight: FontWeight.w700, color: AppColors.onLight, letterSpacingEm: -.01),
                ),
              ),
              Text('Dimanche 25 octobre · départ 9h00', style: AppText.sans(size: 13, color: AppColors.onLightMuted)),
              Padding(
                padding: EdgeInsets.only(top: 16, bottom: 14),
                child: Row(
                  children: [
                    for (final (label, value) in [('CIBLE', '1h28'), ('ALLURE', '4′10'), ('PRÉDIT', '1h29')])
                      Padding(
                        padding: EdgeInsets.only(right: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: AppText.mono(size: 9, color: AppColors.onLightDim, letterSpacingEm: .14)),
                            Text(value, style: AppText.mono(size: 19, weight: FontWeight.w700, color: AppColors.onLight)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              ProgressBar(fraction: .62, color: AppColors.onLight, trackColor: AppColors.onLightTrack),
              SizedBox(height: 8),
              Text('Bloc spécifique — semaine 7 / 12', style: AppText.mono(size: 10, color: AppColors.onLightMuted)),
            ],
          ),
        ),
        SectionLabel('RECORDS PERSONNELS'),
        for (final (tag, label, value, recordDate) in [
          ('CAP', '5 km', '18′42', 'mai 2026'),
          ('CAP', '10 km', '39′10', 'juin 2026'),
          ('CAP', 'Semi-marathon', '1h31′05', 'mars 2026'),
          ('TRAIL', 'D+ sur une sortie', '1 480 m', 'août 2026'),
          ('VÉLO', 'FTP estimée', '272 W', 'sept. 2026'),
          ('NAT', '1 000 m', '17′24', 'juil. 2026'),
        ])
          ListRow(
            leading: Row(
              children: [
                TagPill(
                  tag,
                  size: 8,
                  radius: 4,
                  color: AppColors.label,
                  spacingEm: .1,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                ),
                SizedBox(width: 10),
                Text(label, style: AppText.sans(size: 14, weight: FontWeight.w500)),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: AppText.mono(size: 14, weight: FontWeight.w700)),
                SizedBox(height: 3),
                Text(recordDate, style: AppText.mono(size: 9, color: AppColors.dim)),
              ],
            ),
          ),
        SizedBox(height: 16),
        AppCard(
          radius: 16,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow('SÉRIE EN COURS', color: AppColors.label, spacingEm: .18),
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('18', style: AppText.mono(size: 30, weight: FontWeight.w700)),
                  SizedBox(width: 9),
                  Text('semaines sans interruption', style: AppText.sans(size: 13, color: AppColors.muted)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
