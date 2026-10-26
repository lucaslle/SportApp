import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../models/workout_session.dart';
import '../state/connections_providers.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../utils/training_load.dart';
import '../widgets/ui.dart';

/// Écran 01 — Aujourd'hui.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? const <WorkoutSession>[];
    final athlete = ref.watch(athleteNameProvider).valueOrNull ?? '';
    final stravaConnected = ref.watch(stravaConnectedProvider);

    final todaySessions = SessionsNotifier.forDay(sessions, today)
        .where((session) => !session.isRest)
        .toList();
    final todaySession = todaySessions.isEmpty ? null : todaySessions.first;
    final monday = FrDate.mondayOf(today);
    final week = SessionsNotifier.forWeek(sessions, monday);
    final summary = WeekSummary.of(week);
    final lastSevenDays = sessions.where((session) {
      final delta = FrDate.daysBetween(session.date, today);
      return session.done && delta >= 0 && delta < 7;
    });

    return ScreenScroll(
      children: [
        Eyebrow(FrDate.longDay(today).toUpperCase()),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 20),
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
        const SizedBox(height: 14),
        TileGrid(
          children: [
            StatTile(label: 'CHARGE 7J', value: '${TrainingLoad.sum(lastSevenDays)}', valueSize: 20),
            const StatTile(label: 'FORME', value: '+6', valueSize: 20),
            const StatTile(label: 'SOMMEIL', value: '7h20', valueSize: 20),
          ],
        ),
        const SizedBox(height: 14),
        _WeekCard(week: week, monday: monday, today: today, summary: summary),
        const SizedBox(height: 14),
        AppCard(
          radius: 16,
          padding: const EdgeInsets.all(16),
          onTap: () => context.goTo(AppScreen.body),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('POIDS CORPOREL', color: AppColors.label, spacingEm: .18),
                  const SizedBox(height: 6),
                  Text('68,4 kg', style: AppText.mono(size: 22, weight: FontWeight.w700)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('−0,6 kg', style: AppText.mono(size: 13)),
                  const SizedBox(height: 4),
                  Text('30 jours', style: AppText.mono(size: 10, color: AppColors.mutedDark)),
                ],
              ),
            ],
          ),
        ),
        if (!stravaConnected) ...[
          const SizedBox(height: 14),
          DashedBox(
            radius: 16,
            padding: const EdgeInsets.all(16),
            onTap: () => context.goTo(AppScreen.strava),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connecter Strava', style: AppText.sans(size: 14, weight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      'Import auto des traces GPS',
                      style: AppText.sans(size: 12, color: AppColors.muted),
                    ),
                  ],
                ),
                Text('→', style: AppText.mono(size: 16)),
              ],
            ),
          ),
        ],
      ],
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
          side: const BorderSide(color: AppColors.border),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.text,
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
                  style: AppText.mono(size: 10, color: AppColors.onLight, letterSpacingEm: .18),
                ),
              ),
              const SizedBox(width: 8),
              TagPill(
                pill,
                size: 10,
                color: AppColors.onLight,
                borderColor: AppColors.onLight,
                spacingEm: 0,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              session.title,
              style: AppText.sans(
                size: 22,
                weight: FontWeight.w700,
                color: AppColors.onLight,
                letterSpacingEm: -.01,
              ),
            ),
          ),
          Text(
            session.subtitle.isEmpty ? session.sport.label : session.subtitle,
            style: AppText.sans(size: 13, color: AppColors.onLightMuted),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 18),
            child: Row(
              children: [
                _DarkStat('DURÉE', session.durationLabel),
                const SizedBox(width: 26),
                _DarkStat('VOLUME', _volume(session)),
                const SizedBox(width: 26),
                _DarkStat('CHARGE', '${TrainingLoad.of(session)}'),
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
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onTap: () => context.goTo(AppScreen.session, arguments: session.id),
                ),
              ),
              const SizedBox(width: 10),
              OutlineButton(
                width: 52,
                height: 46,
                radius: 11,
                borderColor: AppColors.onLight,
                onTap: () => context.goTo(AppScreen.watch),
                child: Text('GO', style: AppText.mono(size: 12, color: AppColors.onLight)),
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
        Text(label, style: AppText.mono(size: 9, color: AppColors.onLightDim, letterSpacingEm: .14)),
        Text(value, style: AppText.mono(size: 19, weight: FontWeight.w700, color: AppColors.onLight)),
      ],
    );
  }
}

class _RestDayCard extends StatelessWidget {
  const _RestDayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SÉANCE DU JOUR',
            style: AppText.mono(size: 10, color: AppColors.onLight, letterSpacingEm: .18),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              'Jour de repos',
              style: AppText.sans(size: 22, weight: FontWeight.w700, color: AppColors.onLight),
            ),
          ),
          Text(
            'Rien de planifié aujourd\'hui · mobilité optionnelle',
            style: AppText.sans(size: 13, color: AppColors.onLightMuted),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Voir le plan',
            light: false,
            radius: 11,
            padding: const EdgeInsets.symmetric(vertical: 13),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Eyebrow('CETTE SEMAINE', color: AppColors.label, spacingEm: .18),
              Text(
                '${WorkoutSession.formatDuration(summary.doneMinutes)} / '
                '${WorkoutSession.formatDuration(summary.totalMinutes)}',
                style: AppText.mono(size: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BarColumnChart(items: bars),
        ],
      ),
    );
  }
}
