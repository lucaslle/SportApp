import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../models/sport.dart';
import '../models/workout_session.dart';
import '../state/record_providers.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';
import 'record_sheet.dart';

/// Statistiques de l'app installée, tirées des vraies données : records,
/// volume des 12 dernières semaines et répartition par sport sur 4 semaines.
class StatsOverview extends ConsumerWidget {
  const StatsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? const <WorkoutSession>[];
    final done = sessions.where((session) => session.done && !session.isRest).toList();
    final series = RecordSeries.group(ref.watch(recordsProvider).valueOrNull ?? const <PersonalRecord>[]);

    final monday = FrDate.mondayOf(today);
    final weeks = [for (var i = 11; i >= 0; i--) monday.subtract(Duration(days: 7 * i))];
    final weeklyMinutes = [
      for (final start in weeks)
        SessionsNotifier.forWeek(done, start).fold<int>(0, (sum, session) => sum + session.durationMin),
    ];
    final maxMinutes = weeklyMinutes.fold<int>(0, (a, b) => a > b ? a : b);

    final since = today.subtract(const Duration(days: 28));
    final bySport = <Sport, int>{};
    for (final session in done.where((session) => !session.date.isBefore(since))) {
      bySport[session.sport] = (bySport[session.sport] ?? 0) + session.durationMin;
    }
    final split = bySport.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topSplit = split.isEmpty ? 1 : split.first.value;

    return ScreenScroll(
      children: [
        ScreenHeader(eyebrow: 'STATISTIQUES', title: 'Progression'),
        SectionLabel(
          'RECORDS',
          trailing: GestureDetector(
            onTap: () => context.goTo(AppScreen.goals),
            child: Text('TOUT VOIR →', style: AppText.mono(size: 10, color: AppColors.textPill)),
          ),
        ),
        if (series.isEmpty)
          DashedBox(
            onTap: () => showRecordForm(context),
            child: Center(
              child: Text('+  Ajouter un record', style: AppText.sans(size: 14, weight: FontWeight.w500)),
            ),
          ),
        for (final exercise in series.take(6))
          InkWell(
            onTap: () => showRecordSeries(context, exercise.sport, exercise.label),
            child: ListRow(
              leading: Row(
                children: [
                  TagPill(
                    exercise.sport.code,
                    size: 8,
                    radius: 4,
                    color: AppColors.label,
                    spacingEm: .1,
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  ),
                  SizedBox(width: 10),
                  Flexible(child: Text(exercise.label, style: AppText.sans(size: 14, weight: FontWeight.w500))),
                ],
              ),
              trailing: Text(exercise.best.value, style: AppText.mono(size: 14, weight: FontWeight.w700)),
            ),
          ),
        SizedBox(height: 18),
        if (done.isEmpty)
          EmptyState(
            title: 'Pas encore d\'activité',
            message: 'Le volume et la répartition par sport\napparaîtront avec vos activités',
          )
        else ...[
          AppCard(
            radius: 16,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Eyebrow('VOLUME · 12 SEMAINES', color: AppColors.label, spacingEm: .18)),
                    Text(
                      'cette sem. ${WorkoutSession.formatDuration(weeklyMinutes.last)}',
                      style: AppText.mono(size: 10, color: AppColors.mutedDark),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                BarColumnChart(
                  height: 110,
                  gap: 5,
                  labelSize: 8,
                  labelColor: AppColors.dim,
                  items: [
                    for (var i = 0; i < weeks.length; i++)
                      BarItem(
                        label: 'S${FrDate.isoWeek(weeks[i])}',
                        fraction: maxMinutes == 0 ? 0 : weeklyMinutes[i] / maxMinutes,
                        color: i == weeks.length - 1 ? AppColors.text : AppColors.chartBar,
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          AppCard(
            radius: 16,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Eyebrow('RÉPARTITION PAR SPORT · 4 SEM.', color: AppColors.label, spacingEm: .18),
                ),
                if (split.isEmpty)
                  Text('Aucune activité ces 4 dernières semaines', style: AppText.sans(size: 13, color: AppColors.muted)),
                for (final entry in split)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key.label, style: AppText.mono(size: 11, color: AppColors.textSoft)),
                            Text(
                              WorkoutSession.formatDuration(entry.value),
                              style: AppText.mono(size: 11, color: AppColors.muted),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        ProgressBar(fraction: entry.value / topSplit, color: AppColors.text),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
