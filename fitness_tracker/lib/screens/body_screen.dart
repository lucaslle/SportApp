import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/session_providers.dart';
import '../state/weighing_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/trend_chart.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';

/// Écran 06 — Poids & composition.
class BodyScreen extends ConsumerWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weighings = ref.watch(weighingsProvider).valueOrNull ?? <Weighing>[];
    final today = ref.watch(todayProvider);
    final header = ScreenHeader(
      eyebrow: 'CORPS',
      title: 'Poids & composition',
      trailing: IconButton(
        tooltip: 'Ajouter une pesée',
        onPressed: () => _addWeighing(context, ref, today, weighings),
        icon: Icon(Icons.add, size: 28, color: AppColors.text),
      ),
    );

    if (weighings.isEmpty) {
      return ScreenScroll(
        children: [
          header,
          SizedBox(height: 18),
          EmptyState(
            icon: Icons.monitor_weight_outlined,
            title: 'Aucune pesée',
            message: 'Ajoutez votre première pesée\navec le bouton +',
          ),
        ],
      );
    }

    final latest = weighings.last;
    final delta = weightChange(weighings, today);
    // Les 30 dernières pesées, placées selon leur date.
    final chart = weighings.length > 30 ? weighings.sublist(weighings.length - 30) : weighings;
    final fatChart = chart.where((weighing) => weighing.fatPercent != null).toList();

    return ScreenScroll(
      children: [
        header,
        SizedBox(height: 16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              _decimal(latest.kg),
              style: AppText.mono(size: 46, weight: FontWeight.w700, letterSpacingEm: -.03, height: 1),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('kg', style: AppText.mono(size: 15, color: AppColors.muted)),
            ),
            if (delta != null) ...[
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: TagPill(
                  '${formatKg(delta, signed: true)} · 30j',
                  size: 13,
                  color: AppColors.text,
                  spacingEm: 0,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Pesée du ${FrDate.longDayShortMonth(latest.date).toLowerCase()}',
          style: AppText.mono(size: 10, color: AppColors.mutedDark),
        ),
        SizedBox(height: 16),
        if (chart.length == 1) ...[
          EmptyState(
            icon: Icons.show_chart,
            title: 'Pas encore de courbe',
            message: 'Elle apparaîtra dès une pesée\nsur un autre jour',
          ),
          SizedBox(height: 12),
        ],
        if (chart.length > 1) ...[
          TrendChart(
            title: 'POIDS',
            points: [for (final w in chart) (w.date, w.kg)],
            format: formatKg,
            formatChange: (change) => '${formatKg(change, signed: true)} kg',
          ),
          SizedBox(height: 12),
        ],
        if (fatChart.length > 1) ...[
          TrendChart(
            title: 'MASSE GRASSE',
            points: [for (final w in fatChart) (w.date, w.fatPercent!)],
            format: formatKg,
            formatChange: (change) => '${formatKg(change, signed: true)} %',
          ),
          SizedBox(height: 12),
        ],
        if (latest.fatPercent != null) ...[
          TileGrid(
            columns: 2,
            children: [
              StatTile(label: 'M. GRASSE', value: '${_decimal(latest.fatPercent!)} %', valueSize: 18),
              StatTile(
                label: 'M. GRASSE (KG)',
                value: '${_decimal(latest.kg * latest.fatPercent! / 100)} kg',
                valueSize: 18,
              ),
            ],
          ),
          SizedBox(height: 12),
        ],
        SectionLabel('DERNIÈRES PESÉES', top: 20),
        for (final weighing in weighings.reversed.take(10))
          swipeToDelete(
            key: ValueKey(weighing.date),
            confirm: () => confirmDelete(
              context,
              title: 'Supprimer la pesée ?',
              detail: '${FrDate.longDayShortMonth(weighing.date)} · ${_decimal(weighing.kg)} kg',
            ),
            onDeleted: () => ref.read(weighingsProvider.notifier).remove(weighing),
            child: ListRow(
              leading: Text(FrDate.abbrevDay(weighing.date), style: AppText.mono(size: 12, color: AppColors.label)),
              trailing: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (weighing.fatPercent != null) ...[
                    Text('${_decimal(weighing.fatPercent!)} %',
                        style: AppText.mono(size: 11, color: AppColors.mutedDark)),
                    SizedBox(width: 16),
                  ],
                  Text('${_decimal(weighing.kg)} kg', style: AppText.mono(size: 14, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _decimal(double value) => value.toStringAsFixed(1).replaceAll('.', ',');

  Future<void> _addWeighing(BuildContext context, WidgetRef ref, DateTime today, List<Weighing> existing) async {
    final weighing = await showAppSheet<Weighing>(
      context: context,
      builder: (_) => _WeighingDialog(today: today, existing: existing),
    );
    if (weighing == null) return;
    final replaces = existing.any((other) => FrDate.sameDay(other.date, weighing.date));
    await ref.read(weighingsProvider.notifier).add(weighing);
    if (!context.mounted) return;
    showAppSnack(context, replaces ? 'Pesée du jour remplacée' : 'Pesée enregistrée');
  }
}

/// Saisie d'une pesée : date, poids et masse grasse facultative.
class _WeighingDialog extends StatefulWidget {
  const _WeighingDialog({required this.today, required this.existing});

  final DateTime today;

  /// Pesées déjà enregistrées : une seule est gardée par jour.
  final List<Weighing> existing;

  @override
  State<_WeighingDialog> createState() => _WeighingDialogState();
}

class _WeighingDialogState extends State<_WeighingDialog> {
  late DateTime _date = widget.today;
  final _kg = TextEditingController();
  final _fat = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _kg.dispose();
    _fat.dispose();
    super.dispose();
  }

  double? _parse(String text) => text.trim().isEmpty ? null : double.tryParse(text.trim().replaceAll(',', '.'));

  void _save() {
    final kg = _parse(_kg.text);
    if (kg == null || kg < 20 || kg > 300) {
      setState(() => _error = 'Indiquez un poids entre 20 et 300 kg.');
      return;
    }
    final fat = _parse(_fat.text);
    if (_fat.text.trim().isNotEmpty && (fat == null || fat < 1 || fat > 70)) {
      setState(() => _error = 'La masse grasse va de 1 à 70 %.');
      return;
    }
    Navigator.of(context).pop(Weighing(date: _date, kg: kg, fatPercent: fat));
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.existing.lastOrNull;
    final sameDay = widget.existing.where((other) => FrDate.sameDay(other.date, _date)).firstOrNull;
    return SheetScaffold(
      title: Text('Nouvelle pesée'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlineButton(
            height: 44,
            borderColor: AppColors.border,
            background: AppColors.card,
            onTap: () async {
              final picked = await pickAppDate(context, _date);
              if (picked != null) setState(() => _date = picked);
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.accentText),
              SizedBox(width: 10),
              Text(FrDate.longDayShortMonth(_date), style: AppText.sans(size: 14))
            ]),
          ),
          if (sameDay != null) ...[
            SizedBox(height: 8),
            Text(
              'Remplacera la pesée de ce jour (${BodyScreen._decimal(sameDay.kg)} kg). '
              'Changez la date pour en ajouter une autre.',
              style: AppText.sans(size: 12, color: AppColors.muted),
            ),
          ],
          SizedBox(height: 14),
          TextField(
            controller: _kg,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: AppText.sans(size: 14),
            decoration: InputDecoration(
              labelText: 'Poids (kg)',
              hintText: last == null ? '70,0' : BodyScreen._decimal(last.kg),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _fat,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: AppText.sans(size: 14),
            decoration: InputDecoration(labelText: 'Masse grasse (%) · facultatif'),
            onSubmitted: (_) => _save(),
          ),
          if (_error != null) ...[
            SizedBox(height: 10),
            Text(_error!, style: AppText.sans(size: 12, color: AppColors.textSoft)),
          ],
        ],
      ),
      actions: [
        SheetAction(label: 'Annuler', onPressed: () => Navigator.of(context).pop()),
        SheetAction(label: 'Enregistrer', onPressed: _save),
      ],
    );
  }
}
