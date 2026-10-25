import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_session.dart';
import '../state/connections_providers.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';

/// Écran 05 — Export montre / Garmin.
class WatchScreen extends ConsumerWidget {
  const WatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(garminConnectedProvider);
    final sent = ref.watch(sentToWatchProvider);
    final options = ref.watch(watchOptionsProvider);
    final today = ref.watch(todayProvider);
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? const <WorkoutSession>[];
    final queue = sessions.where((session) {
      final delta = FrDate.daysBetween(today, session.date);
      return !session.isRest && !session.done && delta >= 0 && delta < 7;
    }).toList();

    return ScreenScroll(
      children: [
        const BackLink('SÉANCE'),
        const ScreenHeader(eyebrow: 'MONTRE & GARMIN', title: 'Export vers la montre'),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _Badge(letter: 'G'),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Garmin Connect', style: AppText.sans(size: 16, weight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(
                          connected ? 'Connecté · envoi des séances structurées' : 'Non connecté',
                          style: AppText.mono(size: 10, color: connected ? AppColors.label : AppColors.dim),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ConnectButton(
                    connected: connected,
                    onTap: () => ref.read(garminConnectedProvider.notifier).state = !connected,
                  ),
                ],
              ),
              if (connected) ...[
                const HairLine(),
                Row(
                  children: [
                    const Icon(Icons.watch_outlined, size: 34, color: AppColors.text),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Forerunner 965', style: AppText.sans(size: 14, weight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                            'Synchro il y a 8 min · batterie 74 %',
                            style: AppText.mono(size: 10, color: AppColors.mutedDark),
                          ),
                        ],
                      ),
                    ),
                    const TagPill('ACTIVE', padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4), spacingEm: 0),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (connected) ...[
          SectionLabel(
            'SÉANCES À ENVOYER',
            trailing: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(sentToWatchProvider.notifier).state = {
                ...sent,
                ...queue.map((session) => session.id),
              },
              child: Text('TOUT ENVOYER', style: AppText.mono(size: 10, color: AppColors.textPill)),
            ),
          ),
          if (queue.isEmpty)
            DashedBox(
              child: Center(
                child: Text(
                  'Aucune séance à venir sur 7 jours',
                  style: AppText.sans(size: 13, color: AppColors.textFilter),
                ),
              ),
            ),
          for (var i = 0; i < queue.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _QueueRow(
              session: queue[i],
              sent: sent.contains(queue[i].id),
              onToggle: () {
                final next = {...sent};
                if (!next.remove(queue[i].id)) next.add(queue[i].id);
                ref.read(sentToWatchProvider.notifier).state = next;
              },
            ),
          ],
          const SizedBox(height: 12),
          AppCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Column(
              children: [
                _OptionRow(
                  label: 'Envoi automatique',
                  detail: 'Les séances des 7 prochains jours',
                  value: options.auto,
                  onChanged: (value) =>
                      ref.read(watchOptionsProvider.notifier).state = options.copyWith(auto: value),
                ),
                _OptionRow(
                  label: 'Allures & zones cibles',
                  detail: 'Alertes sur la montre pendant la séance',
                  value: options.targets,
                  onChanged: (value) =>
                      ref.read(watchOptionsProvider.notifier).state = options.copyWith(targets: value),
                ),
                _OptionRow(
                  label: 'Rapatrier les activités',
                  detail: 'Sorties, FC, sommeil depuis Garmin',
                  value: options.sync,
                  last: true,
                  onChanged: (value) =>
                      ref.read(watchOptionsProvider.notifier).state = options.copyWith(sync: value),
                ),
              ],
            ),
          ),
        ],
        const SectionLabel('AUTRES MONTRES'),
        for (final (name, detail) in const [
          ('Coros', 'Séances structurées · activités'),
          ('Suunto', 'Séances structurées · activités'),
          ('Apple Watch', 'Via Apple Santé · activités seules'),
        ]) ...[
          AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppText.sans(size: 14, weight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(detail, style: AppText.mono(size: 10, color: AppColors.mutedDark)),
                    ],
                  ),
                ),
                const TagPill(
                  'CONNECTER',
                  size: 10,
                  color: AppColors.label,
                  spacingEm: 0,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(12)),
      child: Text(letter, style: AppText.mono(size: 15, weight: FontWeight.w700, color: AppColors.onLight)),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.connected, required this.onTap});

  final bool connected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: connected ? Colors.transparent : AppColors.text,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderDashed),
        ),
        child: Text(
          connected ? 'Déconnecter' : 'Connecter',
          style: AppText.sans(
            size: 13,
            weight: FontWeight.w600,
            color: connected ? AppColors.text : AppColors.onLight,
          ),
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.session, required this.sent, required this.onToggle});

  final WorkoutSession session;
  final bool sent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final detail = [
      session.durationLabel,
      if (session.targetPace.isNotEmpty) session.targetPace
      else if (session.targetHr.isNotEmpty) session.targetHr
      else if (session.subtitle.isNotEmpty) session.subtitle,
    ].join(' · ');
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(FrDate.dayShort[session.date.weekday - 1],
                    style: AppText.mono(size: 9, color: AppColors.mutedDark)),
                Text('${session.date.day}', style: AppText.mono(size: 15, weight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.mono(size: 9.5, color: AppColors.mutedDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: sent ? Colors.transparent : AppColors.text,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.borderDashed),
              ),
              child: Text(
                sent ? '✓ SUR LA MONTRE' : 'ENVOYER',
                style: AppText.mono(
                  size: 10,
                  letterSpacingEm: .06,
                  color: sent ? AppColors.label : AppColors.onLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: last ? Colors.transparent : AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.sans(size: 14, weight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(detail, style: AppText.mono(size: 10, color: AppColors.mutedDark)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          AppToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
