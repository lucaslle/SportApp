import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/session_providers.dart';
import '../state/weighing_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';

/// Écran 06 — Poids & composition.
class BodyScreen extends ConsumerWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weighings = ref.watch(weighingsProvider).valueOrNull ?? <Weighing>[];
    final today = ref.watch(todayProvider);
    final addButton = DashedBox(
      padding: EdgeInsets.all(14),
      onTap: () => _addWeighing(context, ref, today, weighings.isEmpty ? null : weighings.last),
      child: Center(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '+  ', style: AppText.mono(size: 14)),
              TextSpan(text: 'Ajouter une pesée', style: AppText.sans(size: 14, weight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );

    if (weighings.isEmpty) {
      return ScreenScroll(
        children: [
          ScreenHeader(eyebrow: 'CORPS', title: 'Poids & composition'),
          SizedBox(height: 18),
          addButton,
          SizedBox(height: 12),
          EmptyState(
            title: 'Aucune pesée',
            message: 'Votre poids et votre masse grasse\napparaîtront ici',
          ),
        ],
      );
    }

    final latest = weighings.last;
    final delta = weightChange(weighings, today);
    final chart = weighings.length > 12 ? weighings.sublist(weighings.length - 12) : weighings;

    return ScreenScroll(
      children: [
        Eyebrow('CORPS'),
        SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _decimal(latest.kg),
              style: AppText.mono(size: 46, weight: FontWeight.w700, letterSpacingEm: -.03, height: 1),
            ),
            SizedBox(width: 12),
            Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('kg', style: AppText.mono(size: 15, color: AppColors.muted)),
            ),
            if (delta != null) ...[
              SizedBox(width: 12),
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
        if (chart.length > 1) ...[
          AppCard(
            radius: 16,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Eyebrow('TENDANCE · ${chart.length} PESÉES', color: AppColors.label, spacingEm: .18),
                    Text('kg', style: AppText.mono(size: 10, color: AppColors.mutedDark)),
                  ],
                ),
                SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(painter: _WeightChartPainter([for (final w in chart) w.kg])),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final weighing in [chart.first, chart.last])
                      Text(FrDate.abbrevDay(weighing.date), style: AppText.mono(size: 9, color: AppColors.dim)),
                  ],
                ),
              ],
            ),
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
        addButton,
        SectionLabel('DERNIÈRES PESÉES', top: 20),
        for (final weighing in weighings.reversed.take(10))
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => _confirmDelete(context, ref, weighing),
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
        SizedBox(height: 10),
        Text(
          'Appui long sur une pesée pour la supprimer',
          textAlign: TextAlign.center,
          style: AppText.mono(size: 10, color: AppColors.dim),
        ),
      ],
    );
  }

  static String _decimal(double value) => value.toStringAsFixed(1).replaceAll('.', ',');

  Future<void> _addWeighing(BuildContext context, WidgetRef ref, DateTime today, Weighing? last) async {
    final weighing = await showDialog<Weighing>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _WeighingDialog(today: today, last: last),
    );
    if (weighing == null) return;
    await ref.read(weighingsProvider.notifier).add(weighing);
    if (!context.mounted) return;
    showAppSnack(context, 'Pesée enregistrée');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Weighing weighing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text('Supprimer la pesée ?', style: AppText.sans(size: 16, weight: FontWeight.w600)),
        content: Text(
          '${FrDate.longDayShortMonth(weighing.date)} · ${_decimal(weighing.kg)} kg',
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
    if (confirmed != true) return;
    await ref.read(weighingsProvider.notifier).remove(weighing);
  }
}

/// Saisie d'une pesée : date, poids et masse grasse facultative.
class _WeighingDialog extends StatefulWidget {
  const _WeighingDialog({required this.today, this.last});

  final DateTime today;
  final Weighing? last;

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
    final last = widget.last;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      title: Text('Nouvelle pesée', style: AppText.sans(size: 16, weight: FontWeight.w600)),
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
            child: Text(FrDate.longDayShortMonth(_date), style: AppText.sans(size: 14)),
          ),
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

class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (final fraction in [.09, .5, .91]) {
      final y = size.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final high = values.reduce((a, b) => a > b ? a : b);
    final low = values.reduce((a, b) => a < b ? a : b);
    final range = high - low < 1 ? 1.0 : high - low;
    double yOf(double value) => size.height * (.09 + (high - value) / range * .82);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++) Offset(i * size.width / (values.length - 1), yOf(values[i])),
    ];

    final trend = Path()
      ..moveTo(points.first.dx, points.first.dy)
      ..lineTo(points.last.dx, points.last.dy);
    final dashed = Paint()
      ..color = AppColors.dimmer
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final metric in trend.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), dashed);
        distance += 8;
      }
    }

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.text
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_WeightChartPainter old) => old.values != values;
}
