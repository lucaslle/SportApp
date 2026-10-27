import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../models/workout_session.dart';
import '../state/connections_providers.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';
import 'session_form_sheet.dart';

/// Course de la saison (données de maquette).
class _Race {
  const _Race(this.name, this.date, this.priority, this.detail);

  final String name;
  final DateTime date;
  final String priority;
  final String detail;
}

List<_Race> _races(String goalRace) => [
      _Race('10 km de Villeurbanne', DateTime(2026, 9, 27), 'C', '10 km'),
      _Race('Trail des Monts du Lyonnais', DateTime(2026, 10, 4), 'B', '25 km · D+ 900'),
      _Race(goalRace, DateTime(2026, 10, 25), 'A', '21,1 km'),
    ];

/// Écran 03 — Calendrier & courses.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final month = ref.watch(calendarMonthProvider);
    final selected = ref.watch(calendarSelectedDayProvider);
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? <WorkoutSession>[];
    final races = ref.watch(demoDataProvider) ? _races(ref.watch(goalRaceProvider)) : <_Race>[];

    void shiftMonth(int delta) {
      final next = DateTime(month.year, month.month + delta);
      ref.read(calendarMonthProvider.notifier).state = next;
      final sameMonthAsToday = next.year == today.year && next.month == today.month;
      ref.read(calendarSelectedDayProvider.notifier).state =
          sameMonthAsToday ? today : DateTime(next.year, next.month, 1);
    }

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    final cellCount = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final selectedSessions = SessionsNotifier.forDay(sessions, selected);
    final selectedRace = races.where((race) => FrDate.sameDay(race.date, selected)).firstOrNull;

    return ScreenScroll(
      children: [
        Row(
          children: [
            Expanded(
              child: ScreenHeader(eyebrow: 'CALENDRIER', title: FrDate.monthYear(month)),
            ),
            OutlineButton(
              width: 36,
              onTap: () => shiftMonth(-1),
              child: Text('‹', style: AppText.mono(size: 14)),
            ),
            SizedBox(width: 8),
            OutlineButton(
              width: 36,
              onTap: () => shiftMonth(1),
              child: Text('›', style: AppText.mono(size: 14)),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            for (final letter in FrDate.dayLetter)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Eyebrow(letter, size: 9, color: AppColors.dim, spacingEm: .1, align: TextAlign.center),
                ),
              ),
          ],
        ),
        SizedBox(height: 6),
        for (var row = 0; row < cellCount ~/ 7; row++) ...[
          if (row > 0) SizedBox(height: 4),
          Row(
            children: [
              for (var column = 0; column < 7; column++) ...[
                if (column > 0) SizedBox(width: 4),
                Expanded(
                  child: _buildCell(
                    context,
                    ref,
                    index: row * 7 + column,
                    leading: leading,
                    daysInMonth: daysInMonth,
                    month: month,
                    today: today,
                    selected: selected,
                    sessions: sessions,
                    races: races,
                  ),
                ),
              ],
            ],
          ),
        ],
        SizedBox(height: 12),
        Row(
          children: [
            _LegendDot(label: 'faite', filled: true),
            SizedBox(width: 16),
            _LegendDot(label: 'prévue', filled: false),
            SizedBox(width: 16),
            _LegendDot(label: 'course', square: true),
          ],
        ),
        SizedBox(height: 16),
        AppCard(
          radius: 16,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Eyebrow(
                    '${FrDate.dayShort[selected.weekday - 1]}. ${selected.day} '
                    '${FrDate.monthLong[selected.month - 1].toUpperCase()}',
                    color: AppColors.label,
                    spacingEm: .18,
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => showSessionForm(context, initialDate: selected),
                    child: Text('+ AJOUTER', style: AppText.mono(size: 10, color: AppColors.textPill)),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (selectedRace != null)
                _SelectedItem(
                  tag: 'COURSE ${selectedRace.priority}',
                  tagBackground: AppColors.divider,
                  title: selectedRace.name,
                  meta: selectedRace.detail,
                ),
              for (final session in selectedSessions) ...[
                if (selectedRace != null || session != selectedSessions.first) SizedBox(height: 10),
                _SelectedItem(
                  tag: session.sport.code,
                  title: session.title,
                  meta: session.durationLabel,
                  done: session.done,
                  onTap: () => context.goTo(AppScreen.session, arguments: session.id),
                ),
              ],
              if (selectedRace == null && selectedSessions.isEmpty)
                Text(
                  'Jour de repos — rien de planifié',
                  style: AppText.sans(size: 13, color: AppColors.dim),
                ),
            ],
          ),
        ),
        SectionLabel(
          'COURSES DE LA SAISON',
          trailing: Text('+ AJOUTER', style: AppText.mono(size: 10, color: AppColors.textPill)),
        ),
        for (var i = 0; i < races.length; i++) ...[
          if (i > 0) SizedBox(height: 8),
          _RaceRow(race: races[i], today: today),
        ],
        if (races.isEmpty)
          EmptyState(
            icon: Icons.flag_outlined,
            title: 'Aucune course prévue',
            message: 'Vos courses de la saison apparaîtront ici',
          ),
        SizedBox(height: 14),
        Text(
          'Priorité A = objectif principal, affûtage 10 j avant.\nB / C = courses de préparation, intégrées au plan.',
          style: AppText.mono(size: 10, color: AppColors.dim, height: 1.7),
        ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required int leading,
    required int daysInMonth,
    required DateTime month,
    required DateTime today,
    required DateTime selected,
    required List<WorkoutSession> sessions,
    required List<_Race> races,
  }) {
    final dayNumber = index - leading + 1;
    if (dayNumber < 1 || dayNumber > daysInMonth) return SizedBox(height: 50);
    final day = DateTime(month.year, month.month, dayNumber);
    final isToday = FrDate.sameDay(day, today);
    final isSelected = FrDate.sameDay(day, selected);
    final isRace = races.any((race) => FrDate.sameDay(race.date, day));
    final isPast = day.isBefore(today);
    final daySessions = SessionsNotifier.forDay(sessions, day).where((s) => !s.isRest).toList();

    final background = isRace
        ? AppColors.text
        : isSelected
            ? AppColors.cardSelected
            : Colors.transparent;
    final border = isToday
        ? AppColors.text
        : isSelected
            ? AppColors.borderDashed
            : Colors.transparent;
    final foreground = isRace
        ? AppColors.onLight
        : isPast
            ? AppColors.muted
            : AppColors.text;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(calendarSelectedDayProvider.notifier).state = day,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: AppText.mono(
                size: 13,
                color: foreground,
                weight: isRace || isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isRace)
                    for (final session in daySessions.take(3)) ...[
                      if (session != daySessions.first) SizedBox(width: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: session.done ? AppColors.text : Colors.transparent,
                          border: Border.all(color: session.done ? AppColors.text : AppColors.label),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, this.filled = false, this.square = false});

  final String label;
  final bool filled;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: square ? 8 : 6,
          height: square ? 8 : 6,
          decoration: BoxDecoration(
            color: filled || square ? AppColors.text : Colors.transparent,
            shape: square ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: square ? BorderRadius.circular(2) : null,
            border: filled || square ? null : Border.all(color: AppColors.label),
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: AppText.mono(size: 9, color: AppColors.mutedDark)),
      ],
    );
  }
}

class _SelectedItem extends StatelessWidget {
  const _SelectedItem({
    required this.tag,
    required this.title,
    required this.meta,
    this.tagBackground = Colors.transparent,
    this.done = false,
    this.onTap,
  });

  final String tag;
  final String title;
  final String meta;
  final Color tagBackground;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Flexible(child: TagPill(tag, spacingEm: .1, background: tagBackground)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(size: 14, weight: FontWeight.w500),
            ),
          ),
          SizedBox(width: 8),
          Text(
            done ? '$meta ✓' : meta,
            style: AppText.mono(size: 11, color: done ? AppColors.text : AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _RaceRow extends StatelessWidget {
  const _RaceRow({required this.race, required this.today});

  final _Race race;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final isMain = race.priority == 'A';
    final foreground = isMain ? AppColors.onLight : AppColors.text;
    final sub = isMain ? AppColors.onLightMuted : AppColors.mutedDark;
    final days = FrDate.daysBetween(today, race.date);
    final countdown = days > 0 ? 'J−$days' : days == 0 ? 'JOUR J' : 'J+${-days}';
    return AppCard(
      color: isMain ? AppColors.text : AppColors.card,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: foreground, width: 1.5),
            ),
            child: Text(race.priority, style: AppText.mono(size: 14, weight: FontWeight.w700, color: foreground)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(race.name, style: AppText.sans(size: 14, weight: FontWeight.w600, color: foreground)),
                SizedBox(height: 4),
                Text(
                  '${FrDate.abbrevDay(race.date).toLowerCase()} · ${race.detail}',
                  style: AppText.mono(size: 10, color: sub),
                ),
              ],
            ),
          ),
          Text(countdown, style: AppText.mono(size: 12, weight: FontWeight.w700, color: foreground)),
        ],
      ),
    );
  }
}
