import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_csv_codec.dart';
import '../models/sport.dart';
import '../models/workout_session.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';

/// Ouvre le formulaire de création ([session] nul) ou d'édition d'une séance.
/// Avec [asActivity], la séance créée est une sortie déjà réalisée.
Future<void> showSessionForm(
  BuildContext context, {
  WorkoutSession? session,
  DateTime? initialDate,
  bool asActivity = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      side: BorderSide(color: AppColors.border),
    ),
    builder: (_) => _SessionFormSheet(session: session, initialDate: initialDate, asActivity: asActivity),
  );
}

class _SessionFormSheet extends ConsumerStatefulWidget {
  const _SessionFormSheet({this.session, this.initialDate, this.asActivity = false});

  final WorkoutSession? session;
  final DateTime? initialDate;
  final bool asActivity;

  @override
  ConsumerState<_SessionFormSheet> createState() => _SessionFormSheetState();
}

class _SessionFormSheetState extends ConsumerState<_SessionFormSheet> {
  late DateTime _date;
  late Sport _sport;
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _duration;
  late final TextEditingController _distance;
  late final TextEditingController _pace;
  late final TextEditingController _hr;
  late final TextEditingController _rpe;
  late final TextEditingController _time;
  late final TextEditingController _location;
  late final TextEditingController _tags;
  late final TextEditingController _structure;
  late final TextEditingController _notes;
  String? _error;

  WorkoutSession? get _existing => widget.session;

  @override
  void initState() {
    super.initState();
    final session = _existing;
    _date = session?.date ?? widget.initialDate ?? FrDate.dateOnly(DateTime.now());
    _sport = session?.sport ?? Sport.cap;
    _title = TextEditingController(text: session?.title ?? '');
    _subtitle = TextEditingController(text: session?.subtitle ?? '');
    _duration = TextEditingController(
      text: session == null || session.durationMin == 0 ? '' : '${session.durationMin}',
    );
    _distance = TextEditingController(text: _formatDistance(session?.distanceKm));
    _pace = TextEditingController(text: session?.targetPace ?? '');
    _hr = TextEditingController(text: session?.targetHr ?? '');
    _rpe = TextEditingController(text: session?.rpe?.toString() ?? '');
    _time = TextEditingController(text: session?.time ?? '');
    _location = TextEditingController(text: session?.location ?? '');
    _tags = TextEditingController(text: session?.tags.join(', ') ?? '');
    _structure = TextEditingController(
      text: session == null ? '' : SessionCsvCodec.encodeBlocks(session.blocks),
    );
    _notes = TextEditingController(text: session?.notes ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _title, _subtitle, _duration, _distance, _pace, _hr, _rpe, _time, _location,
      _tags, _structure, _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatDistance(double? km) {
    if (km == null) return '';
    return km == km.roundToDouble() ? km.toInt().toString() : km.toString();
  }

  Future<void> _pickDate() async {
    final picked = await pickAppDate(context, _date);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Le titre est obligatoire.');
      return;
    }
    final duration = int.tryParse(_duration.text.trim());
    if (_duration.text.trim().isNotEmpty && duration == null) {
      setState(() => _error = 'La durée doit être un nombre de minutes.');
      return;
    }
    final distanceText = _distance.text.trim().replaceAll(',', '.');
    final distance = distanceText.isEmpty ? null : double.tryParse(distanceText);
    if (distanceText.isNotEmpty && distance == null) {
      setState(() => _error = 'La distance doit être un nombre (km).');
      return;
    }
    final rpe = int.tryParse(_rpe.text.trim());
    if (rpe != null && (rpe < 1 || rpe > 10)) {
      setState(() => _error = 'Le RPE va de 1 à 10.');
      return;
    }

    final session = WorkoutSession(
      id: _existing?.id ?? WorkoutSession.newId(),
      date: _date,
      sport: _sport,
      title: title,
      subtitle: _subtitle.text.trim(),
      durationMin: duration ?? 0,
      distanceKm: distance,
      targetPace: _pace.text.trim(),
      targetHr: _hr.text.trim(),
      rpe: rpe,
      time: _time.text.trim(),
      location: _location.text.trim(),
      tags: _tags.text
          .split(RegExp(r'[,|]'))
          .map((tag) => tag.trim().toUpperCase())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      blocks: SessionCsvCodec.decodeBlocks(_structure.text),
      done: _existing?.done ?? widget.asActivity,
      notes: _notes.text.trim(),
    );
    final notifier = ref.read(sessionsProvider.notifier);
    if (_existing == null) {
      await notifier.add(session);
    } else {
      await notifier.edit(session);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .92,
        maxChildSize: .96,
        minChildSize: .5,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.borderDashed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ScreenHeader(
              eyebrow: _existing != null
                  ? 'MODIFIER LA SÉANCE'
                  : widget.asActivity
                      ? 'NOUVELLE SORTIE'
                      : 'NOUVELLE SÉANCE',
              title: _existing?.title ?? (widget.asActivity ? 'Sortie réalisée' : 'Programmer'),
              titleSize: 22,
            ),
            const SizedBox(height: 18),
            const _FieldLabel('DATE'),
            OutlineButton(
              height: 44,
              onTap: _pickDate,
              borderColor: AppColors.border,
              background: AppColors.card,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(FrDate.longDayShortMonth(_date), style: AppText.sans(size: 14)),
                  Text(FrDate.iso(_date), style: AppText.mono(size: 10, color: AppColors.mutedDark)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('SPORT'),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final sport in Sport.values)
                  GestureDetector(
                    onTap: () => setState(() => _sport = sport),
                    child: TagPill(
                      sport.code,
                      size: 10,
                      spacingEm: .1,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      background: sport == _sport ? AppColors.text : Colors.transparent,
                      color: sport == _sport ? AppColors.onLight : AppColors.textFilter,
                      borderColor: AppColors.borderStrong,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _Field(label: 'TITRE', controller: _title, hint: 'Fractionné 8 × 400 m'),
            _Field(label: 'SOUS-TITRE', controller: _subtitle, hint: 'Piste · récup 90″ · objectif 3′20/km'),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'DURÉE (MIN)',
                    controller: _duration,
                    hint: '55',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Field(
                    label: 'DISTANCE (KM)',
                    controller: _distance,
                    hint: '11',
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Field(
                    label: 'RPE / 10',
                    controller: _rpe,
                    hint: '8',
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _Field(label: 'ALLURE CIBLE', controller: _pace, hint: '3′20 /km')),
                const SizedBox(width: 10),
                Expanded(child: _Field(label: 'FC CIBLE', controller: _hr, hint: 'Z4 · 172')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _Field(label: 'HEURE', controller: _time, hint: '18h30')),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _Field(label: 'LIEU', controller: _location, hint: 'Stade Léo Lagrange'),
                ),
              ],
            ),
            _Field(label: 'TAGS (SÉPARÉS PAR DES VIRGULES)', controller: _tags, hint: 'PISTE, VMA'),
            _Field(
              label: 'STRUCTURE · titre~détail~minutes~L/M/H, blocs séparés par |',
              controller: _structure,
              hint: 'Échauffement~Footing souple~20~M | 8 × 400 m~@ 3′20/km~25~H',
              maxLines: 4,
              mono: true,
            ),
            _Field(label: 'NOTES', controller: _notes, hint: 'Sensations, météo, douleurs…', maxLines: 3),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: AppText.sans(size: 12, color: AppColors.textSoft)),
              ),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: _existing != null
                        ? 'Enregistrer'
                        : widget.asActivity
                            ? 'Ajouter la sortie'
                            : 'Ajouter au plan',
                    onTap: _save,
                  ),
                ),
                const SizedBox(width: 10),
                OutlineButton(
                  height: 48,
                  radius: 12,
                  borderColor: AppColors.borderStrong,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: () => Navigator.of(context).pop(),
                  child: Text('Annuler', style: AppText.sans(size: 13, weight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Eyebrow(text, size: 9, spacingEm: .14),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboard,
    this.maxLines = 1,
    this.mono = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final style = mono ? AppText.mono(size: 12) : AppText.sans(size: 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            style: style,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: style.copyWith(color: AppColors.dimmer),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderDashed),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
