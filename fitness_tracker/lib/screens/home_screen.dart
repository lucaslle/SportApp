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
import '../widgets/ui.dart';

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

    final todaySessions = SessionsNotifier.forDay(sessions, today)
        .where((session) => !session.isRest)
        .toList();
    final todaySession = todaySessions.isEmpty ? null : todaySessions.first;
    final monday = FrDate.mondayOf(today);
    final week = SessionsNotifier.forWeek(sessions, monday);
    final summary = WeekSummary.of(week);

    return ScreenScroll(
      children: [
        Row(
          children: [
            Expanded(child: Eyebrow(FrDate.longDay(today).toUpperCase())),
            IconButton(
              tooltip: 'Apparence',
              onPressed: () => _chooseTheme(context, ref),
              icon: Icon(Icons.contrast, color: AppColors.textSoft, size: 24),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 6, bottom: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => _editName(context, ref, athlete),
              borderRadius: BorderRadius.circular(8),
              child: Semantics(
                button: true,
                hint: 'Modifier votre nom',
                child: Text(
                  athlete.isEmpty ? 'Bonjour' : 'Bonjour $athlete',
                  style: AppText.screenTitle(size: 26),
                ),
              ),
            ),
          ),
        ),
        if (todaySession != null)
          _TodaySessionCard(session: todaySession)
        else
          const _RestDayCard(),
        SizedBox(height: 14),
        _WeekCard(week: week, monday: monday, today: today, summary: summary),
        SizedBox(height: 14),
        AppCard(
          radius: 16,
          padding: EdgeInsets.all(16),
          onTap: () => context.goTo(AppScreen.body),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow('POIDS CORPOREL', color: AppColors.label, spacingEm: .18),
                  SizedBox(height: 6),
                  Text(
                    weighings.isEmpty ? 'Aucune pesée' : '${formatKg(weighings.last.kg)} kg',
                    style: AppText.mono(size: 22, weight: FontWeight.w700),
                  ),
                ],
              ),
              if (weightDelta != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${formatKg(weightDelta, signed: true)} kg', style: AppText.mono(size: 13)),
                    SizedBox(height: 4),
                    Text('30 jours', style: AppText.mono(size: 10, color: AppColors.mutedDark)),
                  ],
                )
              else
                Text('→', style: AppText.mono(size: 16)),
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
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text('Votre nom', style: AppText.sans(size: 16, weight: FontWeight.w600)),
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
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Annuler', style: AppText.sans(size: 13, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text('Enregistrer', style: AppText.sans(size: 13, weight: FontWeight.w600)),
          ),
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
                  session.done ? 'SÉANCE FAITE' : 'SÉANCE DU JOUR',
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
              style: AppText.sans(
                size: 22,
                weight: FontWeight.w700,
                color: AppColors.onAccent,
                letterSpacingEm: -.01,
              ),
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
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Voir la séance',
                  light: false,
                  radius: 11,
                  padding: EdgeInsets.symmetric(vertical: 13),
                  onTap: () => context.goTo(AppScreen.session, arguments: session.id),
                ),
              ),
              SizedBox(width: 10),
              OutlineButton(
                width: 52,
                height: 46,
                radius: 11,
                borderColor: AppColors.onAccent,
                onTap: () => context.goTo(AppScreen.watch),
                child: Text('GO', style: AppText.mono(size: 12, color: AppColors.onAccent)),
              ),
            ],
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
        Text(label, style: AppText.mono(size: 9, color: AppColors.onAccentMuted, letterSpacingEm: .14)),
        Text(value, style: AppText.mono(size: 19, weight: FontWeight.w700, color: AppColors.onAccent)),
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
            'SÉANCE DU JOUR',
            style: AppText.mono(size: 10, color: AppColors.onAccent, letterSpacingEm: .18),
          ),
          Padding(
            padding: EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              'Jour de repos',
              style: AppText.sans(size: 22, weight: FontWeight.w700, color: AppColors.onAccent),
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
  });

  final List<WorkoutSession> week;
  final DateTime monday;
  final DateTime today;
  final WeekSummary summary;

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
          color: donePerDay[i] ? AppColors.text : AppColors.barOff,
        ),
    ];
    return AppCard(
      radius: 16,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Eyebrow('CETTE SEMAINE', color: AppColors.label, spacingEm: .18),
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
