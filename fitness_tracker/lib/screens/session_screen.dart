import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../models/workout_session.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';
import 'rest_timer_sheet.dart';
import 'session_form_sheet.dart';

/// Écran 04 — Détail de séance.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key, required this.sessionId});

  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? <WorkoutSession>[];
    final session = sessions.where((candidate) => candidate.id == sessionId).firstOrNull;

    if (session == null) {
      return ScreenScroll(
        children: [
          BackLink('PLAN'),
          Text('Séance introuvable', style: AppText.screenTitle()),
          SizedBox(height: 8),
          Text(
            'Elle a peut-être été supprimée ou remplacée par un import.',
            style: AppText.sans(size: 13, color: AppColors.muted),
          ),
        ],
      );
    }

    final meta = [
      FrDate.longDayShortMonth(session.date),
      if (session.time.isNotEmpty) session.time,
      if (session.location.isNotEmpty) session.location,
    ].join(' · ');

    return ScreenScroll(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackLink('PLAN', onTap: () => _backToPlan(context)),
            Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  _ActionLink('MODIFIER', onTap: () => showSessionForm(context, session: session)),
                  SizedBox(width: 16),
                  _ActionLink('SUPPRIMER', onTap: () => _confirmDelete(context, ref, session)),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            sportTag(session.sport),
            for (final tag in session.tags) TagPill(tag),
          ],
        ),
        SizedBox(height: 12),
        Text(session.title, style: AppText.screenTitle(size: 26)),
        SizedBox(height: 6),
        Text(meta, style: AppText.sans(size: 13, color: AppColors.muted)),
        if (session.subtitle.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(session.subtitle, style: AppText.sans(size: 13, color: AppColors.muted)),
        ],
        SizedBox(height: 18),
        TileGrid(
          columns: 2,
          children: [
            StatTile(
              label: 'ALLURE CIBLE',
              value: session.targetPace.isEmpty ? '—' : session.targetPace,
              valueSize: 18,
              padding: EdgeInsets.all(14),
            ),
            StatTile(
              label: 'FC CIBLE',
              value: session.targetHr.isEmpty ? '—' : session.targetHr,
              valueSize: 18,
              padding: EdgeInsets.all(14),
            ),
            StatTile(
              label: 'VOLUME',
              value: _volume(session),
              valueSize: 18,
              padding: EdgeInsets.all(14),
            ),
            StatTile(
              label: 'RPE PRÉVU',
              value: session.rpe == null ? '—' : '${session.rpe} / 10',
              valueSize: 18,
              padding: EdgeInsets.all(14),
            ),
          ],
        ),
        SectionLabel('STRUCTURE'),
        if (session.blocks.isEmpty)
          DashedBox(
            onTap: () => showSessionForm(context, session: session),
            child: Center(
              child: Text(
                'Ajouter la structure de la séance',
                style: AppText.sans(size: 14, weight: FontWeight.w500),
              ),
            ),
          )
        else
          for (var i = 0; i < session.blocks.length; i++) ...[
            if (i > 0) SizedBox(height: 8),
            _BlockRow(block: session.blocks[i], onTap: () => showRestTimer(context, session.blocks[i])),
          ],
        SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow('NOTE POST-SÉANCE', spacingEm: .18),
              SizedBox(height: 10),
              Text(
                session.notes.isEmpty ? 'Sensations, météo, douleurs…' : session.notes,
                style: AppText.sans(
                  size: 13,
                  color: session.notes.isEmpty ? AppColors.dim : AppColors.textSoft,
                  fontStyle: session.notes.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: session.done ? 'Marquer à faire' : 'Marquer comme faite',
                onTap: () => ref.read(sessionsProvider.notifier).toggleDone(session.id),
              ),
            ),
            SizedBox(width: 10),
            OutlineButton(
              height: 48,
              radius: 12,
              borderColor: AppColors.borderStrong,
              padding: EdgeInsets.symmetric(horizontal: 14),
              onTap: () => context.goTo(AppScreen.watch),
              child: Row(
                children: [
                  Icon(Icons.watch_outlined, size: 17, color: AppColors.text),
                  SizedBox(width: 8),
                  Text('Montre', style: AppText.sans(size: 12.5, weight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _backToPlan(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.switchTab(AppTab.plan);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final confirmed = await showAppSheet<bool>(
      context: context,
      builder: (dialogContext) => SheetScaffold(
        title: Text('Supprimer la séance ?'),
        content: Text(
          '« ${session.title} » sera retirée du plan.',
          style: AppText.sans(size: 13, color: AppColors.muted),
        ),
        actions: [
          SheetAction(label: 'Annuler', onPressed: () => Navigator.of(dialogContext).pop(false)),
          SheetAction(label: 'Supprimer', onPressed: () => Navigator.of(dialogContext).pop(true), destructive: true),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(sessionsProvider.notifier).remove(session.id);
    if (!context.mounted) return;
    showAppSnack(context, 'Séance supprimée');
    _backToPlan(context);
  }

  String _volume(WorkoutSession session) {
    final km = session.distanceKm;
    if (km == null) return session.durationLabel;
    final text = km == km.roundToDouble() ? km.toInt().toString() : km.toStringAsFixed(1);
    return '${text.replaceAll('.', ',')} km';
  }
}

class _ActionLink extends StatelessWidget {
  const _ActionLink(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(label, style: AppText.mono(size: 10, color: AppColors.textPill, letterSpacingEm: .08)),
    );
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({required this.block, required this.onTap});

  final SessionBlock block;

  /// Ouvre le compteur de repos de l'exercice.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (block.intensity) {
      BlockIntensity.high => AppColors.text,
      BlockIntensity.medium => AppColors.blockMedium,
      BlockIntensity.low => AppColors.blockLow,
    };
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 38,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(block.title, style: AppText.sans(size: 14, weight: FontWeight.w500)),
                if (block.detail.isNotEmpty) ...[
                  SizedBox(height: 3),
                  Text(block.detail, style: AppText.sans(size: 12, color: AppColors.muted)),
                ],
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            WorkoutSession.formatDuration(block.durationMin),
            style: AppText.mono(size: 12, color: AppColors.textPill),
          ),
          SizedBox(width: 10),
          Icon(Icons.timer_outlined, size: 22, color: AppColors.textSoft),
        ],
      ),
    );
  }
}
