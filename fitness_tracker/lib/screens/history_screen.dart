import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../models/sport.dart';
import '../models/workout_session.dart';
import '../services/garmin_service.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';
import 'session_form_sheet.dart';

const List<String> _filters = ['TOUT', 'CAP', 'TRAIL', 'VÉLO', 'HT', 'NAT', 'MUSCU'];

final _historyFilterProvider = StateProvider<String>((ref) => 'TOUT');

/// Écran 07 — Historique des sorties : les séances marquées faites.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_historyFilterProvider);
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? const <WorkoutSession>[];
    final all = sessions.where((session) => session.done && !session.isRest).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final activities = filter == 'TOUT' ? all : all.where((session) => session.sport.code == filter).toList();
    final totalKm = all.fold<double>(0, (sum, session) => sum + (session.distanceKm ?? 0));

    return ScreenScroll(
      children: [
        ScreenHeader(
          eyebrow: 'HISTORIQUE',
          title: 'Mes sorties',
          trailing: all.isEmpty
              ? null
              : Text(
                  '${all.length} sortie${all.length > 1 ? 's' : ''}\n${formatKm(totalKm)} km',
                  textAlign: TextAlign.right,
                  style: AppText.mono(size: 10, color: AppColors.mutedDark, height: 1.5),
                ),
        ),
        const SizedBox(height: 16),
        DashedBox(
          onTap: () => showSessionForm(context, initialDate: ref.read(todayProvider), asActivity: true),
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '+  ', style: AppText.mono(size: 14)),
                  TextSpan(text: 'Ajouter une sortie', style: AppText.sans(size: 14, weight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
        // L'API Garmin refuse les appels depuis un navigateur : import réservé à l'app installée.
        if (!kIsWeb) ...[
          const SizedBox(height: 8),
          const _GarminImportButton(),
        ],
        if (all.isNotEmpty)
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
          )
        else
          const SizedBox(height: 12),
        for (var i = 0; i < activities.length; i++) ...[
          if (i == 0 || activities[i].date.month != activities[i - 1].date.month)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 4 : 14, bottom: 10),
              child: Eyebrow(FrDate.monthYear(activities[i].date).toUpperCase(), color: AppColors.dim),
            )
          else
            const SizedBox(height: 8),
          _ActivityCard(session: activities[i]),
        ],
        if (all.isEmpty)
          const EmptyState(
            title: 'Aucune sortie pour l\'instant',
            message: 'Ajoutez une sortie, ou cochez « faite »\nsur une séance du plan',
          )
        else if (activities.isEmpty)
          const EmptyState(
            title: 'Aucune sortie sur ce filtre',
            message: 'Essayez un autre sport',
          ),
      ],
    );
  }
}

/// "10" ou "10,5".
String formatKm(double km) {
  if (km == km.roundToDouble()) return km.toInt().toString();
  return km.toStringAsFixed(1).replaceAll('.', ',');
}

/// Allure en min/km (course, trail), min/100 m (natation) ou vitesse en km/h (vélo).
String formatPace(WorkoutSession session) {
  final km = session.distanceKm;
  final minutes = session.durationMin;
  if (km == null || km <= 0 || minutes <= 0) return '—';
  String minSec(double totalMinutes) {
    final seconds = (totalMinutes * 60).round();
    return '${seconds ~/ 60}′${(seconds % 60).toString().padLeft(2, '0')}';
  }

  return switch (session.sport) {
    Sport.velo || Sport.ht => '${(km / (minutes / 60)).toStringAsFixed(1).replaceAll('.', ',')} km/h',
    Sport.nat => '${minSec(minutes / (km * 10))}/100',
    Sport.cap || Sport.trail => minSec(minutes / km),
    _ => '—',
  };
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final km = session.distanceKm;
    final isBike = session.sport == Sport.velo || session.sport == Sport.ht;
    return AppCard(
      onTap: () => context.goTo(
        session.garminId.isEmpty ? AppScreen.session : AppScreen.activity,
        arguments: session.id,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TagPill(
                session.sport.code,
                radius: 4,
                spacingEm: .1,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  [FrDate.abbrevDay(session.date), if (session.time.isNotEmpty) session.time].join(' · '),
                  style: AppText.mono(size: 10, color: AppColors.mutedDark),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(session.title, style: AppText.sans(size: 15, weight: FontWeight.w600)),
          ),
          Wrap(
            spacing: 22,
            runSpacing: 8,
            children: [
              _Metric('DIST', km == null ? '—' : '${formatKm(km)} km'),
              _Metric('TEMPS', session.durationLabel),
              _Metric(isBike ? 'VITESSE' : 'ALLURE', formatPace(session)),
              _Metric('RPE', session.rpe?.toString() ?? '—'),
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

/// Importe les nouvelles sorties Garmin et leurs traces ; demande la clé la première fois.
class _GarminImportButton extends ConsumerStatefulWidget {
  const _GarminImportButton();

  @override
  ConsumerState<_GarminImportButton> createState() => _GarminImportButtonState();
}

class _GarminImportButtonState extends ConsumerState<_GarminImportButton> {
  static const _keys = GarminKeyStore();
  /// Avancement de l'import en cours ; null hors import.
  String? _progress;

  Future<void> _import() async {
    final apiKey = await _keys.read() ?? await _askKey();
    if (apiKey == null || apiKey.trim().isEmpty || !mounted) return;
    setState(() => _progress = '');
    try {
      final current = ref.read(sessionsProvider).valueOrNull ?? const <WorkoutSession>[];
      final fresh = await const GarminService().importNew(
        apiKey,
        known: {for (final session in current) if (session.garminId.isNotEmpty) session.garminId},
        onProgress: (done, total) {
          if (mounted) setState(() => _progress = '$done / $total traces');
        },
      );
      await _keys.write(apiKey);
      await ref.read(sessionsProvider.notifier).importSessions(fresh, mode: ImportMode.merge);
      if (!mounted) return;
      showAppSnack(
        context,
        fresh.isEmpty
            ? 'Aucune nouvelle sortie Garmin'
            : '${fresh.length} sortie${fresh.length > 1 ? 's' : ''} Garmin importée${fresh.length > 1 ? 's' : ''}',
      );
    } on GarminException catch (error) {
      // Une clé refusée est oubliée pour pouvoir en saisir une autre au prochain essai.
      if (error.message.startsWith('Clé Garmin refusée')) await _keys.delete();
      if (!mounted) return;
      showAppSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  Future<String?> _askKey() async {
    final controller = TextEditingController();
    final apiKey = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Clé API Garmin', style: AppText.sans(size: 16, weight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créez une clé personnelle sur le site Garmin Connect, dans les paramètres '
              'de l\'API personnelle, puis collez-la ici. Elle reste chiffrée sur ce téléphone.',
              style: AppText.sans(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              style: AppText.mono(size: 12),
              decoration: const InputDecoration(labelText: 'Clé personnelle'),
              onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Annuler', style: AppText.sans(size: 13, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text('Importer', style: AppText.sans(size: 13, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    controller.dispose();
    return apiKey;
  }

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      height: 46,
      borderColor: AppColors.borderStrong,
      onTap: _progress == null ? _import : null,
      child: Text(
        _progress == null ? '⟳  Importer depuis Garmin' : 'Import Garmin… $_progress',
        style: AppText.sans(size: 14, weight: FontWeight.w500),
      ),
    );
  }
}
