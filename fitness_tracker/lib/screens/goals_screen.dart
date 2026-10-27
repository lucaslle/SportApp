import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/connections_providers.dart';
import '../state/record_providers.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';
import 'record_sheet.dart';

/// Écran 11 — Objectifs & records.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalRace = ref.watch(goalRaceProvider);
    final today = ref.watch(todayProvider);
    final raceDay = DateTime(2026, 10, 25);
    final days = FrDate.daysBetween(today, raceDay);
    final countdown = days > 0
        ? 'J−$days'
        : days == 0
            ? 'JOUR J'
            : 'J+${-days}';

    final demo = ref.watch(demoDataProvider);
    final series = RecordSeries.group(ref.watch(recordsProvider).valueOrNull ?? const <PersonalRecord>[]);

    return ScreenScroll(
      children: [
        BackLink('STATS'),
        ScreenHeader(
          eyebrow: 'OBJECTIFS',
          title: demo ? 'Course cible & records' : 'Records',
          trailing: IconButton(
            tooltip: 'Ajouter un record',
            onPressed: () => showRecordForm(context),
            icon: Icon(Icons.add, size: 28, color: AppColors.text),
          ),
        ),
        SizedBox(height: 18),
        // La course cible et la série restent des exemples de la démo web.
        if (demo)
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
                    TagPill(countdown,
                        size: 10, color: AppColors.onLight, borderColor: AppColors.onLight, spacingEm: 0),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    goalRace,
                    style: AppText.sans(
                        size: 21, weight: FontWeight.w700, color: AppColors.onLight, letterSpacingEm: -.01),
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
                              Text(label,
                                  style: AppText.mono(size: 9, color: AppColors.onLightDim, letterSpacingEm: .14)),
                              Text(value,
                                  style: AppText.mono(size: 19, weight: FontWeight.w700, color: AppColors.onLight)),
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
        if (series.isEmpty)
          EmptyState(
            title: 'Aucun record',
            message: 'Ajoutez vos meilleures performances\net vos charges max avec le bouton +',
          ),
        for (final exercise in series)
          InkWell(
            onTap: () => showRecordSeries(context, exercise.sport, exercise.label),
            child: ListRow(
              leading: Row(
                children: [
                  sportTag(
                    exercise.sport,
                    size: 8,
                    radius: 4,
                    spacingEm: .1,
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  ),
                  SizedBox(width: 10),
                  Flexible(child: Text(exercise.label, style: AppText.sans(size: 14, weight: FontWeight.w500))),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(exercise.best.value, style: AppText.mono(size: 14, weight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text(
                        exercise.entries.length > 1
                            ? '${exercise.entries.length} mesures'
                            : FrDate.abbrevDay(exercise.best.date),
                        style: AppText.mono(size: 9, color: AppColors.dim),
                      ),
                    ],
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 20, color: AppColors.dim),
                ],
              ),
            ),
          ),
        if (demo) ...[
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
      ],
    );
  }
}
