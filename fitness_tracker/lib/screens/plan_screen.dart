import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../models/workout_session.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../theme/sport_colors.dart';
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
    final sessions = sessionsAsync.valueOrNull ?? <WorkoutSession>[];
    final week = SessionsNotifier.forWeek(sessions, monday);
    final summary = WeekSummary.of(week);

    void shiftWeek(int weeks) {
      ref.read(weekMondayProvider.notifier).state = monday.add(Duration(days: 7 * weeks));
    }

    return ScreenScroll(
      children: [
        ScreenHeader(
          eyebrow: 'PLAN · SEMAINE ${FrDate.isoWeek(monday)}',
          title: FrDate.weekRange(monday),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Ajouter une séance',
                onPressed: () => showSessionForm(context, initialDate: _defaultNewDate(monday, today)),
                icon: Icon(Icons.add, size: 28, color: AppColors.text),
              ),
              PopupMenuButton<String>(
                tooltip: 'Plus d\'options',
                icon: Icon(Icons.more_vert, color: AppColors.text),
                color: AppColors.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (action) async {
                  switch (action) {
                    case 'month':
                      context.goTo(AppScreen.calendar);
                    case 'csv':
                      showCsvSheet(context, weekMonday: monday);
                    case 'duplicate':
                      final count = await ref.read(sessionsProvider.notifier).duplicateWeek(monday);
                      if (!context.mounted) return;
                      showAppSnack(context, '$count séances copiées sur la semaine suivante');
                  }
                },
                itemBuilder: (_) => [
                  for (final (value, label, icon) in [
                    ('month', 'Vue du mois', Icons.calendar_month_outlined),
                    ('csv', 'Importer ou exporter (CSV)', Icons.import_export),
                    if (week.isNotEmpty) ('duplicate', 'Copier sur la semaine suivante', Icons.copy_all_outlined),
                  ])
                    PopupMenuItem(
                      value: value,
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: AppColors.textSoft),
                          SizedBox(width: 12),
                          Text(label, style: AppText.sans(size: 14)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: 'Semaine précédente',
              onPressed: () => shiftWeek(-1),
              icon: Icon(Icons.chevron_left, color: AppColors.text),
            ),
            Expanded(
              child: Text(
                FrDate.sameDay(monday, FrDate.mondayOf(today)) ? 'Cette semaine' : 'Semaine ${FrDate.isoWeek(monday)}',
                textAlign: TextAlign.center,
                style: AppText.sans(size: 14, weight: FontWeight.w600, color: AppColors.textSoft),
              ),
            ),
            IconButton(
              tooltip: 'Semaine suivante',
              onPressed: () => shiftWeek(1),
              icon: Icon(Icons.chevron_right, color: AppColors.text),
            ),
          ],
        ),
        SizedBox(height: 18),
        TileGrid(
          children: [
            StatTile(label: 'SÉANCES', value: '${summary.sessionCount}'),
            StatTile(label: 'TEMPS', value: WorkoutSession.formatDuration(summary.totalMinutes)),
            StatTile(label: 'CAP', value: '${_km(summary.runningKm)} km'),
          ],
        ),
        SizedBox(height: 16),
        if (sessionsAsync.isLoading && sessions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Chargement du plan…', style: AppText.mono(size: 11, color: AppColors.dim)),
            ),
          )
        else
          for (var offset = 0; offset < 7; offset++) ...[
            if (offset > 0) SizedBox(height: 8),
            _DayRows(
              day: monday.add(Duration(days: offset)),
              today: today,
              sessions: SessionsNotifier.forDay(week, monday.add(Duration(days: offset))),
            ),
          ],
      ],
    );
  }

  DateTime _defaultNewDate(DateTime monday, DateTime today) {
    final sunday = monday.add(Duration(days: 6));
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
          if (i > 0) SizedBox(height: 8),
          _DayRow(
            day: day,
            today: today,
            tag: [sessions[i].sport.code, ...sessions[i].tags.take(1)].join(' · '),
            tagColor: sessions[i].sport.color,
            duration: sessions[i].durationLabel,
            title: sessions[i].title,
            state: sessions[i].isRest
                ? '○'
                : sessions[i].done
                    ? '✓'
                    : '→',
            stateColor: sessions[i].isRest
                ? AppColors.dimmer
                : sessions[i].done
                    ? AppColors.accentText
                    : AppColors.muted,
            onTap: () => context.goTo(AppScreen.session, arguments: sessions[i].id),
          ),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  _DayRow({
    required this.day,
    required this.today,
    required this.tag,
    this.tagColor,
    required this.duration,
    required this.title,
    required this.state,
    required this.stateColor,
    required this.onTap,
    Color? titleColor,
  }) : titleColor = titleColor ?? AppColors.text;

  final DateTime day;
  final DateTime today;
  final String tag;

  /// Couleur du sport de la séance ; gris pour un jour sans séance.
  final Color? tagColor;
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
                Text(FrDate.dayShort[day.weekday - 1], style: AppText.mono(size: 9, color: AppColors.mutedDark)),
                Text('${day.day}', style: AppText.mono(size: 16, weight: FontWeight.w700)),
              ],
            ),
          ),
          SizedBox(width: 14),
          Container(width: 1, height: 34, color: AppColors.divider),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: TagPill(
                        tag,
                        color: tagColor,
                        borderColor: tagColor?.withValues(alpha: .55),
                        background: tagColor?.withValues(alpha: .12) ?? Colors.transparent,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      duration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mono(size: 10, color: AppColors.mutedDark),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 14, weight: FontWeight.w500, color: titleColor),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Icon(
            switch (state) {
              '✓' => Icons.check_circle,
              '○' => Icons.radio_button_unchecked,
              _ => Icons.chevron_right,
            },
            size: 20,
            color: stateColor,
          ),
        ],
      ),
    );
  }
}
