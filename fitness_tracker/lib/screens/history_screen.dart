import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../state/connections_providers.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Sortie réalisée (données de maquette).
class ActivityRecord {
  const ActivityRecord({
    required this.tag,
    required this.date,
    required this.title,
    required this.distance,
    required this.time,
    required this.pace,
    required this.elevation,
    required this.fromStrava,
  });

  final String tag;
  final String date;
  final String title;
  final String distance;
  final String time;
  final String pace;
  final String elevation;
  final bool fromStrava;
}

const List<ActivityRecord> sampleActivities = [
  ActivityRecord(tag: 'TRAIL', date: 'Dim 13 · 8h04', title: 'Trail des Crêtes', distance: '18,4 km', time: '1h47', pace: '5′49', elevation: '612 m', fromStrava: true),
  ActivityRecord(tag: 'CAP', date: 'Ven 11 · 7h12', title: 'Footing matinal', distance: '10,2 km', time: '48′30', pace: '4′45', elevation: '58 m', fromStrava: true),
  ActivityRecord(tag: 'HT', date: 'Jeu 10 · 19h00', title: 'Home trainer — seuil 3×8′', distance: '32,0 km', time: '1h05', pace: '—', elevation: '—', fromStrava: false),
  ActivityRecord(tag: 'NAT', date: 'Mer 9 · 12h30', title: 'Piscine — technique', distance: '1 500 m', time: '38′', pace: '2′32/100', elevation: '—', fromStrava: false),
  ActivityRecord(tag: 'VÉLO', date: 'Mar 8 · 17h45', title: 'Boucle des vignes', distance: '62,4 km', time: '2h11', pace: '28,6 km/h', elevation: '740 m', fromStrava: true),
  ActivityRecord(tag: 'MUSCU', date: 'Mar 8 · 7h30', title: 'Renfo bas du corps + gainage', distance: '—', time: '45′', pace: '—', elevation: '—', fromStrava: false),
  ActivityRecord(tag: 'CAP', date: 'Lun 7 · 18h20', title: 'Fractionné 10 × 300 m', distance: '9,6 km', time: '52′', pace: '4′10', elevation: '24 m', fromStrava: true),
];

const List<String> _filters = ['TOUT', 'CAP', 'TRAIL', 'VÉLO', 'HT', 'NAT', 'MUSCU'];

final _historyFilterProvider = StateProvider<String>((ref) => 'TOUT');

/// Écran 07 — Historique des sorties.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_historyFilterProvider);
    final connected = ref.watch(stravaConnectedProvider);
    final all = ref.watch(demoDataProvider) ? sampleActivities : const <ActivityRecord>[];
    final activities = filter == 'TOUT' ? all : all.where((activity) => activity.tag == filter).toList();

    return ScreenScroll(
      children: [
        ScreenHeader(
          eyebrow: 'HISTORIQUE',
          title: 'Mes sorties',
          trailing: all.isEmpty ? null : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.goTo(AppScreen.strava),
            child: Text(
              '148 sorties\n2 412 km',
              textAlign: TextAlign.right,
              style: AppText.mono(size: 10, color: AppColors.mutedDark, height: 1.5),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final label in _filters)
                GestureDetector(
                  onTap: () => ref.read(_historyFilterProvider.notifier).state = label,
                  child: TagPill(
                    label,
                    size: 10,
                    spacingEm: .1,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    borderColor: AppColors.borderStrong,
                    background: filter == label ? AppColors.text : Colors.transparent,
                    color: filter == label ? AppColors.onLight : AppColors.textFilter,
                  ),
                ),
            ],
          ),
        ),
        if (all.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 10),
            child: Eyebrow('SEPTEMBRE 2026', color: AppColors.dim),
          ),
        for (var i = 0; i < activities.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ActivityCard(activity: activities[i], stravaConnected: connected),
        ],
        if (all.isEmpty)
          const EmptyState(
            title: 'Aucune sortie pour l\'instant',
            message: 'Vos sorties réalisées apparaîtront ici',
          )
        else if (activities.isEmpty)
          const EmptyState(
            title: 'Aucune sortie sur ce filtre',
            message: 'Ce mois-ci · essayez un autre sport\nou saisissez une séance manuellement',
          ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.stravaConnected});

  final ActivityRecord activity;
  final bool stravaConnected;

  @override
  Widget build(BuildContext context) {
    final source = activity.fromStrava
        ? stravaConnected
            ? 'STRAVA'
            : 'À IMPORTER'
        : 'MANUEL';
    final sourceColor = activity.fromStrava && stravaConnected ? const Color(0xFFE0E0E0) : AppColors.dim;
    return AppCard(
      onTap: () => context.goTo(AppScreen.activity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  TagPill(
                    activity.tag,
                    radius: 4,
                    spacingEm: .1,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  ),
                  const SizedBox(width: 9),
                  Text(activity.date, style: AppText.mono(size: 10, color: AppColors.mutedDark)),
                ],
              ),
              Text(source, style: AppText.mono(size: 10, color: sourceColor)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(activity.title, style: AppText.sans(size: 15, weight: FontWeight.w600)),
          ),
          Row(
            children: [
              _Metric('DIST', activity.distance),
              const SizedBox(width: 22),
              _Metric('TEMPS', activity.time),
              const SizedBox(width: 22),
              _Metric('ALLURE', activity.pace),
              const SizedBox(width: 22),
              _Metric('D+', activity.elevation),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label, size: 8, color: AppColors.dim, spacingEm: .12),
        const SizedBox(height: 3),
        Text(value, style: AppText.mono(size: 14, weight: FontWeight.w700)),
      ],
    );
  }
}
