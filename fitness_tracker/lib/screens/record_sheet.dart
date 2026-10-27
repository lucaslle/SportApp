import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sport.dart';
import '../state/record_providers.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/trend_chart.dart';
import '../widgets/ui.dart';

/// Formulaire d'un record : nouveau, nouvelle mesure d'un exercice ([sport] et
/// [label]) ou modification d'une mesure ([record]).
Future<void> showRecordForm(BuildContext context, {PersonalRecord? record, Sport? sport, String? label}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final records = container.read(recordsProvider).valueOrNull ?? const <PersonalRecord>[];
  final saved = await showDialog<PersonalRecord>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _RecordDialog(
      record: record,
      sport: sport,
      label: label,
      today: container.read(todayProvider),
      knownLabels: {
        for (final sport in Sport.values)
          sport: {
            for (final r in records)
              if (r.sport == sport) r.label
          },
      },
    ),
  );
  if (saved == null) return;
  final notifier = container.read(recordsProvider.notifier);
  if (record == null) {
    await notifier.add(saved);
  } else {
    await notifier.replace(record, saved);
  }
}

/// Page d'un exercice : meilleure mesure, courbe de progression et historique.
Future<void> showRecordSeries(BuildContext context, Sport sport, String label) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      side: BorderSide(color: AppColors.border),
    ),
    builder: (_) => _SeriesSheet(sport: sport, label: label),
  );
}

class _SeriesSheet extends ConsumerWidget {
  const _SeriesSheet({required this.sport, required this.label});

  final Sport sport;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider).valueOrNull ?? const <PersonalRecord>[];
    final series = RecordSeries.group(records)
        .where((s) => s.sport == sport && s.label.toLowerCase() == label.toLowerCase())
        .firstOrNull;
    if (series == null) {
      // Dernière mesure supprimée : l'exercice n'existe plus.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
      return SizedBox.shrink();
    }
    final points = series.points;
    final isTime = parseRecordValue(series.best.value)?.$2 ?? false;
    final unit = RegExp(r'[a-zA-Z%]+$').stringMatch(series.best.value.trim()) ?? '';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      maxChildSize: .95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: AppColors.borderDashed, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          ScreenHeader(
            eyebrow: '${sport.label.toUpperCase()} · RECORD',
            title: label,
            titleSize: 22,
            trailing: IconButton(
              tooltip: 'Ajouter une mesure',
              onPressed: () => showRecordForm(context, sport: sport, label: series.label),
              icon: Icon(Icons.add, size: 28, color: AppColors.text),
            ),
          ),
          SizedBox(height: 14),
          Text(series.best.value, style: AppText.mono(size: 34, weight: FontWeight.w700)),
          Text(
            'Meilleure mesure · ${FrDate.longDayShortMonth(series.best.date).toLowerCase()}',
            style: AppText.sans(size: 13, color: AppColors.muted),
          ),
          SizedBox(height: 16),
          if (points.length > 1)
            TrendChart(
              title: 'PROGRESSION',
              points: points,
              format: (value) => formatRecordValue(value, isTime: isTime),
              formatChange: (change) {
                final text = formatRecordValue(change.abs(), isTime: isTime);
                final sign = change > 0
                    ? '+'
                    : change < 0
                        ? '−'
                        : '';
                return '$sign$text${unit.isEmpty || isTime ? '' : ' $unit'}';
              },
            )
          else
            EmptyState(
              title: 'Pas encore de courbe',
              message: 'Ajoutez une mesure avec le bouton +\npour suivre votre progression',
            ),
          SectionLabel('HISTORIQUE'),
          for (final entry in series.entries.reversed)
            InkWell(
              onTap: () => showRecordForm(context, record: entry),
              onLongPress: () => _confirmDelete(context, ref, entry),
              child: ListRow(
                leading: Text(FrDate.abbrevDay(entry.date), style: AppText.mono(size: 12, color: AppColors.label)),
                trailing: Text(entry.value, style: AppText.mono(size: 14, weight: FontWeight.w700)),
              ),
            ),
          SizedBox(height: 10),
          Text(
            'Touchez une mesure pour la modifier, appui long pour la supprimer',
            textAlign: TextAlign.center,
            style: AppText.mono(size: 10, color: AppColors.dim),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, PersonalRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text('Supprimer la mesure ?', style: AppText.sans(size: 16, weight: FontWeight.w600)),
        content: Text(
          '${record.label} · ${record.value} · ${FrDate.abbrevDay(record.date)}',
          style: AppText.sans(size: 13, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Annuler', style: AppText.sans(size: 13, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Supprimer', style: AppText.sans(size: 13, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(recordsProvider.notifier).remove(record);
  }
}

/// Saisie ou modification d'un record : sport, épreuve, performance et date.
class _RecordDialog extends StatefulWidget {
  const _RecordDialog({required this.today, required this.knownLabels, this.record, this.sport, this.label});

  final DateTime today;

  /// Épreuves déjà saisies, par sport, proposées en raccourci.
  final Map<Sport, Set<String>> knownLabels;
  final PersonalRecord? record;

  /// Exercice prérempli pour ajouter une nouvelle mesure.
  final Sport? sport;
  final String? label;

  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  late Sport _sport = widget.record?.sport ?? widget.sport ?? Sport.cap;
  late DateTime _date = widget.record?.date ?? widget.today;
  late final _label = TextEditingController(text: widget.record?.label ?? widget.label ?? '');
  late final _value = TextEditingController(text: widget.record?.value ?? '');
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    super.dispose();
  }

  /// Exercices de musculation courants, puis les épreuves déjà saisies pour ce sport.
  static const List<String> _liftExamples = [
    'Tractions',
    'Pompes',
    'Dips',
    'Squat',
    'Développé couché',
    'Soulevé de terre',
    'Développé militaire',
    'Traction lestée',
  ];

  List<String> get _suggestions {
    if (widget.label != null || widget.record != null) return const [];
    return {...?widget.knownLabels[_sport], if (_sport == Sport.muscu) ..._liftExamples}.take(10).toList();
  }

  void _save() {
    if (_label.text.trim().isEmpty || _value.text.trim().isEmpty) {
      setState(() => _error = 'Indiquez l\'épreuve et la performance.');
      return;
    }
    Navigator.of(context).pop(PersonalRecord(
      sport: _sport,
      label: _label.text.trim(),
      value: _value.text.trim(),
      date: _date,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      title: Text(
        widget.record != null
            ? 'Modifier la mesure'
            : widget.label != null
                ? 'Nouvelle mesure'
                : 'Nouveau record',
        style: AppText.sans(size: 16, weight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final sport in Sport.values.where((sport) => !sport.isRest))
                  GestureDetector(
                    onTap: () => setState(() => _sport = sport),
                    child: TagPill(
                      sport.code,
                      size: 10,
                      spacingEm: .1,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      background: sport == _sport ? AppColors.text : Colors.transparent,
                      color: sport == _sport ? AppColors.onLight : AppColors.textFilter,
                      borderColor: AppColors.borderStrong,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (_suggestions.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final suggestion in _suggestions)
                    ActionChip(
                      label: Text(suggestion, style: AppText.sans(size: 12)),
                      backgroundColor: AppColors.card,
                      side: BorderSide(color: AppColors.border),
                      onPressed: () => setState(() => _label.text = suggestion),
                    ),
                ],
              ),
              SizedBox(height: 8),
            ],
            TextField(
              controller: _label,
              autofocus: widget.record == null && widget.label == null,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.sans(size: 14),
              decoration: InputDecoration(labelText: 'Épreuve', hintText: '10 km, semi-marathon, FTP…'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _value,
              style: AppText.sans(size: 14),
              decoration: InputDecoration(
                labelText: _sport == Sport.muscu ? 'Max : charge ou répétitions' : 'Performance',
                hintText: _sport == Sport.muscu ? '100 kg, 15 reps…' : '39′10, 1h31′05, 272 W…',
              ),
              onSubmitted: (_) => _save(),
            ),
            SizedBox(height: 12),
            OutlineButton(
              height: 44,
              borderColor: AppColors.border,
              background: AppColors.card,
              onTap: () async {
                final picked = await pickAppDate(context, _date);
                if (picked != null) setState(() => _date = picked);
              },
              child: Text('Le ${FrDate.longDayShortMonth(_date).toLowerCase()}', style: AppText.sans(size: 14)),
            ),
            if (_error != null) ...[
              SizedBox(height: 10),
              Text(_error!, style: AppText.sans(size: 12, color: AppColors.textSoft)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annuler', style: AppText.sans(size: 13, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: _save,
          child: Text('Enregistrer', style: AppText.sans(size: 13, weight: FontWeight.w600)),
        ),
      ],
    );
  }
}
