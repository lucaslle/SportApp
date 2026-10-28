import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../models/workout_session.dart';
import '../state/connections_providers.dart';
import '../state/session_providers.dart';
import '../state/theme_providers.dart';
import '../state/weighing_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../utils/typography.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';
import 'history_screen.dart' show formatKm;
import 'record_sheet.dart';
import 'session_form_sheet.dart';

/// Écran 01 — Aujourd'hui.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? <WorkoutSession>[];
    final athlete = ref.watch(athleteNameProvider).valueOrNull ?? '';
    final weighings = ref.watch(weighingsProvider).valueOrNull ?? const <Weighing>[];
    final weightDelta = weightChange(weighings, today);

    final todaySessions = SessionsNotifier.forDay(sessions, today).where((session) => !session.isRest).toList();
    final todaySession = todaySessions.isEmpty ? null : todaySessions.first;
    final monday = FrDate.mondayOf(today);
    final week = SessionsNotifier.forWeek(sessions, monday);
    final summary = WeekSummary.of(week);

    final doneCount = week.where((session) => session.done && !session.isRest).length;
    void openWeek() {
      ref.read(weekMondayProvider.notifier).state = monday;
      context.goTo(AppScreen.plan);
    }

    return ScreenScroll(
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => _editName(context, ref, athlete),
              customBorder: CircleBorder(),
              child: Semantics(
                button: true,
                label: 'Modifier votre nom',
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    athlete.isEmpty ? 'H' : athlete.characters.first.toUpperCase(),
                    style: AppText.display(size: 24, color: AppColors.onAccent),
                  ),
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(FrDate.longDay(today), style: AppText.sans(size: 13, color: AppColors.muted)),
                  Text(athlete.isEmpty ? 'Bonjour' : 'Bonjour $athlete', style: AppText.display(size: 28)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Apparence',
              onPressed: () => _chooseTheme(context, ref),
              icon: Icon(Icons.contrast, color: AppColors.textSoft, size: 24),
            ),
          ],
        ),
        SizedBox(height: 20),
        if (todaySession != null) _TodaySessionCard(session: todaySession) else const _RestDayCard(),
        SizedBox(height: 24),
        _SectionTitle('Cette semaine'),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.check_circle_outline,
                value: '$doneCount/${summary.sessionCount}',
                label: 'séances',
                onTap: openWeek,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.timer_outlined,
                value: WorkoutSession.formatDuration(summary.doneMinutes),
                label: 'd\'effort',
                onTap: openWeek,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.directions_run,
                value: formatKm(summary.runningKm),
                label: 'km course',
                onTap: openWeek,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        _WeekCard(week: week, monday: monday, today: today, summary: summary, onTap: openWeek),
        SizedBox(height: 24),
        _SectionTitle('Raccourcis'),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.directions_run,
                label: 'Activité',
                onTap: () => showSessionForm(context, initialDate: today, asActivity: true),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.monitor_weight_outlined,
                label: 'Pesée',
                onTap: () => context.goTo(AppScreen.body),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.emoji_events_outlined,
                label: 'Record',
                onTap: () => showRecordForm(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        _SectionTitle('Corps'),
        AppCard(
          onTap: () => context.goTo(AppScreen.body),
          child: Row(
            children: [
              _IconBadge(Icons.monitor_weight_outlined),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Poids', style: AppText.sans(size: 13, color: AppColors.muted)),
                    Text(
                      weighings.isEmpty ? 'Aucune pesée' : '${formatKg(weighings.last.kg)} kg',
                      style: AppText.display(size: 26),
                    ),
                  ],
                ),
              ),
              if (weightDelta != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${formatKg(weightDelta, signed: true)} kg · 30 j',
                    style: AppText.sans(size: 12, weight: FontWeight.w600, color: AppColors.accentText),
                  ),
                ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppColors.dim),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _chooseTheme(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apparence', style: AppText.sans(size: 18, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final (mode, label, icon) in const [
                (ThemeMode.system, 'Comme le téléphone', Icons.brightness_auto),
                (ThemeMode.light, 'Clair', Icons.light_mode_outlined),
                (ThemeMode.dark, 'Sombre', Icons.dark_mode_outlined),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon, color: AppColors.text),
                  title: Text(label, style: AppText.sans(size: 15)),
                  trailing: mode == current ? Icon(Icons.check, color: AppColors.text) : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ref.read(themeModeProvider.notifier).choose(mode);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showAppSheet<String>(
      context: context,
      builder: (dialogContext) => SheetScaffold(
        title: Text('Votre nom'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: AppText.sans(size: 14),
          decoration: InputDecoration(
            hintText: 'Prénom',
            hintStyle: AppText.sans(size: 14, color: AppColors.dimmer),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          SheetAction(label: 'Annuler', onPressed: () => Navigator.of(dialogContext).pop()),
          SheetAction(label: 'Enregistrer', onPressed: () => Navigator.of(dialogContext).pop(controller.text)),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    await ref.read(athleteNameProvider.notifier).rename(name);
  }
}

class _TodaySessionCard extends StatelessWidget {
  const _TodaySessionCard({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final pill = [session.sport.code, ...session.tags.take(1)].join(' · ');
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  session.done ? 'Séance faite' : 'Séance du jour',
                  style: AppText.mono(size: 10, color: AppColors.onAccent, letterSpacingEm: .18),
                ),
              ),
              SizedBox(width: 8),
              TagPill(
                pill,
                size: 10,
                color: AppColors.onAccent,
                borderColor: AppColors.onAccent,
                spacingEm: 0,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              session.title,
              style: AppText.display(size: 32, color: AppColors.onAccent),
            ),
          ),
          Text(
            session.subtitle.isEmpty ? session.sport.label : session.subtitle,
            style: AppText.sans(size: 13, color: AppColors.onAccentMuted),
          ),
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 18),
            child: Row(
              children: [
                _DarkStat('DURÉE', session.durationLabel),
                SizedBox(width: 26),
                _DarkStat('VOLUME', _volume(session)),
                if (session.rpe != null) ...[
                  SizedBox(width: 26),
                  _DarkStat('RPE', '${session.rpe}/10'),
                ],
              ],
            ),
          ),
          PrimaryButton(
            label: 'Voir la séance',
            light: false,
            radius: 14,
            padding: EdgeInsets.symmetric(vertical: 15),
            onTap: () => context.goTo(AppScreen.session, arguments: session.id),
          ),
        ],
      ),
    );
  }

  String _volume(WorkoutSession session) {
    final km = session.distanceKm;
    if (km == null) return '—';
    final text = km == km.roundToDouble() ? km.toInt().toString() : km.toStringAsFixed(1);
    return '${text.replaceAll('.', ',')} km';
  }
}

class _DarkStat extends StatelessWidget {
  const _DarkStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sentenceCase(label), style: AppText.sans(size: 13, color: AppColors.onAccentMuted)),
        Text(value, style: AppText.display(size: 24, color: AppColors.onAccent)),
      ],
    );
  }
}

class _RestDayCard extends StatelessWidget {
  const _RestDayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aujourd’hui',
            style: AppText.mono(size: 10, color: AppColors.onAccent, letterSpacingEm: .18),
          ),
          Padding(
            padding: EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              'Jour de repos',
              style: AppText.display(size: 30, color: AppColors.onAccent),
            ),
          ),
          Text(
            'Rien de planifié aujourd\'hui · mobilité optionnelle',
            style: AppText.sans(size: 13, color: AppColors.onAccentMuted),
          ),
          SizedBox(height: 18),
          PrimaryButton(
            label: 'Voir le plan',
            light: false,
            radius: 11,
            padding: EdgeInsets.symmetric(vertical: 13),
            onTap: () => context.switchTab(AppTab.plan),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.week,
    required this.monday,
    required this.today,
    required this.summary,
    required this.onTap,
  });

  final List<WorkoutSession> week;
  final DateTime monday;
  final DateTime today;
  final WeekSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minutesPerDay = List<int>.filled(7, 0);
    final donePerDay = List<bool>.filled(7, false);
    for (final session in week) {
      final index = session.date.weekday - 1;
      minutesPerDay[index] += session.durationMin;
      donePerDay[index] = donePerDay[index] || session.done;
    }
    final maxMinutes = minutesPerDay.fold(0, (a, b) => a > b ? a : b);
    final bars = [
      for (var i = 0; i < 7; i++)
        BarItem(
          label: FrDate.dayLetter[i],
          fraction: maxMinutes == 0 ? 0 : minutesPerDay[i] / maxMinutes,
          color: donePerDay[i] ? AppColors.accent : AppColors.barOff,
        ),
    ];
    return AppCard(
      radius: 16,
      padding: EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Volume par jour', style: AppText.sans(size: 13, color: AppColors.muted)),
              Text(
                '${WorkoutSession.formatDuration(summary.doneMinutes)} / '
                '${WorkoutSession.formatDuration(summary.totalMinutes)}',
                style: AppText.mono(size: 12),
              ),
            ],
          ),
          SizedBox(height: 16),
          BarColumnChart(items: bars),
        ],
      ),
    );
  }
}

/// Titre de section de l'accueil.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text(text, style: AppText.sans(size: 17, weight: FontWeight.w700)),
    );
  }
}

/// Icône dans une pastille teintée de l'accent.
class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: .14), shape: BoxShape.circle),
      child: Icon(icon, size: 22, color: AppColors.accentText),
    );
  }
}

/// Chiffre clé de la semaine.
class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.icon, required this.value, required this.label, required this.onTap});

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accentText),
          SizedBox(height: 10),
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppText.display(size: 26))),
          Text(label, style: AppText.sans(size: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// Raccourci vers une saisie courante.
class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          _IconBadge(icon),
          SizedBox(height: 8),
          Text(label, style: AppText.sans(size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
