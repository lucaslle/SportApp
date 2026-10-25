import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../models/workout_session.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';
import 'csv_sheet.dart';
import 'session_form_sheet.dart';

/// Écran 02 — Plan de la semaine.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monday = ref.watch(weekMondayProvider);
    final today = ref.watch(todayProvider);
    final sessionsAsync = ref.watch(sessionsProvider);
    final sessions = sessionsAsync.valueOrNull ?? const <WorkoutSession>[];
    final week = SessionsNotifier.forWeek(sessions, monday);
    final summary = WeekSummary.of(week);

    void shiftWeek(int weeks) {
      ref.read(weekMondayProvider.notifier).state = monday.add(Duration(days: 7 * weeks));
    }

    return ScreenScroll(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ScreenHeader(
                eyebrow: 'PLAN — SEMAINE ${FrDate.isoWeek(monday)}',
                title: FrDate.weekRange(monday),
              ),
            ),
            OutlineButton(
              onTap: () => context.goTo(AppScreen.calendar),
              child: Text('MOIS', style: AppText.mono(size: 10, letterSpacingEm: .08)),
            ),
            const SizedBox(width: 8),
            OutlineButton(
              onTap: () => showCsvSheet(context, weekMonday: monday),
              child: Text('CSV', style: AppText.mono(size: 10, letterSpacingEm: .08)),
            ),
            const SizedBox(width: 8),
            OutlineButton(
              width: 36,
              onTap: () => shiftWeek(-1),
              child: Text('‹', style: AppText.mono(size: 14)),
            ),
            const SizedBox(width: 8),
            OutlineButton(
              width: 36,
              onTap: () => shiftWeek(1),
              child: Text('›', style: AppText.mono(size: 14)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TileGrid(
          children: [
            StatTile(label: 'SÉANCES', value: '${summary.sessionCount}'),
            StatTile(label: 'TEMPS', value: WorkoutSession.formatDuration(summary.totalMinutes)),
            StatTile(label: 'CAP', value: '${_km(summary.runningKm)} km'),
          ],
        ),
        const SizedBox(height: 16),
        if (sessionsAsync.isLoading && sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Chargement du plan…', style: AppText.mono(size: 11, color: AppColors.dim)),
            ),
          )
        else
          for (var offset = 0; offset < 7; offset++) ...[
            if (offset > 0) const SizedBox(height: 8),
            _DayRows(
              day: monday.add(Duration(days: offset)),
              today: today,
              sessions: SessionsNotifier.forDay(week, monday.add(Duration(days: offset))),
            ),
          ],
        const SizedBox(height: 12),
        DashedBox(
          onTap: () => showSessionForm(context, initialDate: _defaultNewDate(monday, today)),
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '+  ', style: AppText.mono(size: 14)),
                  TextSpan(
                    text: 'Ajouter une séance',
                    style: AppText.sans(size: 14, weight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: week.isEmpty
              ? null
              : () async {
                  final count = await ref.read(sessionsProvider.notifier).duplicateWeek(monday);
                  if (!context.mounted) return;
                  showAppSnack(context, '$count séances dupliquées sur la semaine suivante');
                },
          child: Text(
            'Plan construit à la main · dupliquer la semaine\npour la reporter sur le bloc suivant',
            textAlign: TextAlign.center,
            style: AppText.mono(size: 10, color: AppColors.dim, height: 1.6),
          ),
        ),
      ],
    );
  }

  DateTime _defaultNewDate(DateTime monday, DateTime today) {
    final sunday = monday.add(const Duration(days: 6));
    if (today.isBefore(monday) || today.isAfter(sunday)) return monday;
    return today;
  }

  static String _km(double km) {
    if (km == km.roundToDouble()) return km.toInt().toString();
    return km.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _DayRows extends StatelessWidget {
  const _DayRows({required this.day, required this.today, required this.sessions});

  final DateTime day;
  final DateTime today;
  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return _DayRow(
        day: day,
        today: today,
        tag: 'REPOS',
        duration: '—',
        title: 'Rien de planifié',
        titleColor: AppColors.dim,
        state: '○',
        stateColor: AppColors.dimmer,
        onTap: () => showSessionForm(context, initialDate: day),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < sessions.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _DayRow(
            day: day,
            today: today,
            tag: [sessions[i].sport.code, ...sessions[i].tags.take(1)].join(' · '),
            duration: sessions[i].durationLabel,
            title: sessions[i].title,
            state: sessions[i].isRest ? '○' : sessions[i].done ? '✓' : '→',
            stateColor: sessions[i].isRest
                ? AppColors.dimmer
                : sessions[i].done
                    ? AppColors.text
                    : AppColors.muted,
            onTap: () => context.goTo(AppScreen.session, arguments: sessions[i].id),
          ),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.today,
    required this.tag,
    required this.duration,
    required this.title,
    required this.state,
    required this.stateColor,
    required this.onTap,
    this.titleColor = AppColors.text,
  });

  final DateTime day;
  final DateTime today;
  final String tag;
  final String duration;
  final String title;
  final String state;
  final Color stateColor;
  final VoidCallback onTap;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    final isToday = FrDate.sameDay(day, today);
    return AppCard(
      onTap: onTap,
      borderColor: isToday ? AppColors.borderDashed : AppColors.border,
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(FrDate.dayShort[day.weekday - 1],
                    style: AppText.mono(size: 9, color: AppColors.mutedDark)),
                Text('${day.day}', style: AppText.mono(size: 16, weight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 34, color: AppColors.divider),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: TagPill(tag)),
                    const SizedBox(width: 8),
                    Text(
                      duration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mono(size: 10, color: AppColors.mutedDark),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 14, weight: FontWeight.w500, color: titleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(state, style: AppText.mono(size: 13, color: stateColor)),
        ],
      ),
    );
  }
}
