import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sport.dart';
import '../state/connections_providers.dart';
import '../state/record_providers.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';

/// Écran 11 — Objectifs & records.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalRace = ref.watch(goalRaceProvider);
    final today = ref.watch(todayProvider);
    final raceDay = DateTime(2026, 10, 25);
    final days = FrDate.daysBetween(today, raceDay);
    final countdown = days > 0
        ? 'J−$days'
        : days == 0
            ? 'JOUR J'
            : 'J+${-days}';

    final demo = ref.watch(demoDataProvider);
    final records = ref.watch(recordsProvider).valueOrNull ?? const <PersonalRecord>[];

    return ScreenScroll(
      children: [
        BackLink('STATS'),
        ScreenHeader(
          eyebrow: 'OBJECTIFS',
          title: demo ? 'Course cible & records' : 'Records',
          trailing: IconButton(
            tooltip: 'Ajouter un record',
            onPressed: () => _editRecord(context, ref),
            icon: Icon(Icons.add, size: 28, color: AppColors.text),
          ),
        ),
        SizedBox(height: 18),
        // La course cible et la série restent des exemples de la démo web.
        if (demo)
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OBJECTIF PRINCIPAL',
                      style: AppText.mono(size: 10, color: AppColors.onLight, letterSpacingEm: .18),
                    ),
                    TagPill(countdown,
                        size: 10, color: AppColors.onLight, borderColor: AppColors.onLight, spacingEm: 0),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    goalRace,
                    style: AppText.sans(
                        size: 21, weight: FontWeight.w700, color: AppColors.onLight, letterSpacingEm: -.01),
                  ),
                ),
                Text('Dimanche 25 octobre · départ 9h00', style: AppText.sans(size: 13, color: AppColors.onLightMuted)),
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 14),
                  child: Row(
                    children: [
                      for (final (label, value) in [('CIBLE', '1h28'), ('ALLURE', '4′10'), ('PRÉDIT', '1h29')])
                        Padding(
                          padding: EdgeInsets.only(right: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label,
                                  style: AppText.mono(size: 9, color: AppColors.onLightDim, letterSpacingEm: .14)),
                              Text(value,
                                  style: AppText.mono(size: 19, weight: FontWeight.w700, color: AppColors.onLight)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                ProgressBar(fraction: .62, color: AppColors.onLight, trackColor: AppColors.onLightTrack),
                SizedBox(height: 8),
                Text('Bloc spécifique — semaine 7 / 12', style: AppText.mono(size: 10, color: AppColors.onLightMuted)),
              ],
            ),
          ),
        SectionLabel('RECORDS PERSONNELS'),
        if (records.isEmpty)
          EmptyState(
            title: 'Aucun record',
            message: 'Ajoutez vos meilleures performances\navec le bouton +',
          ),
        for (final record in records)
          InkWell(
            onTap: () => _editRecord(context, ref, record),
            onLongPress: () => _confirmDelete(context, ref, record),
            child: ListRow(
              leading: Row(
                children: [
                  TagPill(
                    record.sport.code,
                    size: 8,
                    radius: 4,
                    color: AppColors.label,
                    spacingEm: .1,
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  ),
                  SizedBox(width: 10),
                  Flexible(child: Text(record.label, style: AppText.sans(size: 14, weight: FontWeight.w500))),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(record.value, style: AppText.mono(size: 14, weight: FontWeight.w700)),
                  SizedBox(height: 3),
                  Text(FrDate.abbrevDay(record.date), style: AppText.mono(size: 9, color: AppColors.dim)),
                ],
              ),
            ),
          ),
        if (records.isNotEmpty) ...[
          SizedBox(height: 10),
          Text(
            'Touchez un record pour le modifier, appui long pour le supprimer',
            textAlign: TextAlign.center,
            style: AppText.mono(size: 10, color: AppColors.dim),
          ),
        ],
        if (demo) ...[
          SizedBox(height: 16),
          AppCard(
            radius: 16,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('SÉRIE EN COURS', color: AppColors.label, spacingEm: .18),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('18', style: AppText.mono(size: 30, weight: FontWeight.w700)),
                    SizedBox(width: 9),
                    Text('semaines sans interruption', style: AppText.sans(size: 13, color: AppColors.muted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _editRecord(BuildContext context, WidgetRef ref, [PersonalRecord? record]) async {
    final saved = await showDialog<PersonalRecord>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _RecordDialog(record: record, today: ref.read(todayProvider)),
    );
    if (saved == null) return;
    final notifier = ref.read(recordsProvider.notifier);
    if (record != null) await notifier.remove(record);
    await notifier.add(saved);
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
        title: Text('Supprimer le record ?', style: AppText.sans(size: 16, weight: FontWeight.w600)),
        content: Text(
          '${record.sport.code} · ${record.label} · ${record.value}',
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
  const _RecordDialog({required this.today, this.record});

  final DateTime today;
  final PersonalRecord? record;

  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  late Sport _sport = widget.record?.sport ?? Sport.cap;
  late DateTime _date = widget.record?.date ?? widget.today;
  late final _label = TextEditingController(text: widget.record?.label ?? '');
  late final _value = TextEditingController(text: widget.record?.value ?? '');
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    super.dispose();
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
        widget.record == null ? 'Nouveau record' : 'Modifier le record',
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
            TextField(
              controller: _label,
              autofocus: widget.record == null,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.sans(size: 14),
              decoration: InputDecoration(labelText: 'Épreuve', hintText: '10 km, semi-marathon, FTP…'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _value,
              style: AppText.sans(size: 14),
              decoration: InputDecoration(labelText: 'Performance', hintText: '39′10, 1h31′05, 272 W…'),
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
