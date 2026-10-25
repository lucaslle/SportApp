import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_csv_codec.dart';
import '../models/sport.dart';
import '../models/workout_session.dart';
import '../services/csv_transfer_service.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../widgets/ui.dart';

/// Feuille d'import / export CSV de la programmation.
Future<void> showCsvSheet(BuildContext context, {required DateTime weekMonday}) {
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
    builder: (_) => _CsvSheet(weekMonday: weekMonday),
  );
}

class _CsvSheet extends ConsumerStatefulWidget {
  const _CsvSheet({required this.weekMonday});

  final DateTime weekMonday;

  @override
  ConsumerState<_CsvSheet> createState() => _CsvSheetState();
}

class _CsvSheetState extends ConsumerState<_CsvSheet> {
  static const CsvTransferService _transfer = CsvTransferService();

  ImportMode _mode = ImportMode.merge;
  bool _busy = false;

  /// Message affiché dans la feuille (une notification serait masquée par elle).
  String? _status;

  void _showStatus(String message) => setState(() => _status = message);

  Future<void> _export({required bool wholePlan}) async {
    final notifier = ref.read(sessionsProvider.notifier);
    final csv = notifier.exportCsv(weekMonday: wholePlan ? null : widget.weekMonday);
    final suffix = wholePlan ? 'plan' : 'semaine-${FrDate.isoWeek(widget.weekMonday)}';
    final fileName = 'seances-$suffix-${FrDate.iso(widget.weekMonday)}.csv';
    await _run(() async {
      final outcome = await _transfer.saveCsv(fileName: fileName, csv: csv);
      if (!mounted) return;
      if (!outcome.saved) return;
      Navigator.of(context).pop();
      showAppSnack(context, 'Export enregistré : $fileName');
    });
  }

  Future<void> _copyToClipboard() async {
    final csv = ref.read(sessionsProvider.notifier).exportCsv();
    try {
      await Clipboard.setData(ClipboardData(text: csv));
    } on PlatformException {
      if (mounted) _showStatus('Copie refusée par le système. Utilisez l\'export en fichier.');
      return;
    }
    if (!mounted) return;
    _showStatus('CSV du plan copié dans le presse-papiers.');
  }

  Future<void> _import() async {
    await _run(() async {
      final text = await _transfer.pickCsvText();
      if (text == null || !mounted) return;
      final List<WorkoutSession> incoming;
      try {
        incoming = SessionCsvCodec.decode(text);
      } on CsvImportException catch (error) {
        _showStatus('Import refusé. $error');
        return;
      }
      if (incoming.isEmpty) {
        _showStatus('Aucune séance dans ce fichier.');
        return;
      }
      final result = await ref
          .read(sessionsProvider.notifier)
          .importSessions(incoming, mode: _mode);
      if (!mounted) return;
      final first = incoming.map((session) => session.date).reduce((a, b) => a.isBefore(b) ? a : b);
      ref.read(weekMondayProvider.notifier).state = FrDate.mondayOf(first);
      Navigator.of(context).pop();
      final detail = _mode == ImportMode.replace
          ? 'plan remplacé'
          : result.replaced == 0
              ? 'ajoutées au plan'
              : '${result.replaced} mises à jour';
      showAppSnack(context, '${result.imported} séances importées · $detail');
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action();
    } on Exception catch (error) {
      if (mounted) _showStatus('Opération impossible : $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? const <WorkoutSession>[];
    final weekCount = SessionsNotifier.forWeek(sessions, widget.weekMonday).length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .88,
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
          const ScreenHeader(
            eyebrow: 'IMPORT / EXPORT CSV',
            title: 'Programmation des séances',
            titleSize: 22,
          ),
          if (_status != null) ...[
            const SizedBox(height: 14),
            DashedBox(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => setState(() => _status = null),
              child: Text(_status!, style: AppText.sans(size: 13, color: AppColors.textSoft, height: 1.4)),
            ),
          ],
          const SectionLabel('EXPORTER', top: 20),
          _ActionRow(
            title: 'Cette semaine',
            detail: '${FrDate.weekRange(widget.weekMonday)} · $weekCount séance${weekCount > 1 ? 's' : ''}',
            action: 'CSV',
            enabled: !_busy && weekCount > 0,
            onTap: () => _export(wholePlan: false),
          ),
          const SizedBox(height: 8),
          _ActionRow(
            title: 'Tout le plan',
            detail: '${sessions.length} séance${sessions.length > 1 ? 's' : ''} · toutes les semaines',
            action: 'CSV',
            enabled: !_busy && sessions.isNotEmpty,
            onTap: () => _export(wholePlan: true),
          ),
          const SizedBox(height: 8),
          _ActionRow(
            title: 'Copier le plan',
            detail: 'Texte CSV dans le presse-papiers',
            action: 'COPIER',
            enabled: !_busy && sessions.isNotEmpty,
            filled: false,
            onTap: _copyToClipboard,
          ),
          const SectionLabel('IMPORTER'),
          AppCard(
            radius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ModeChip(
                        label: 'AJOUTER / FUSIONNER',
                        selected: _mode == ImportMode.merge,
                        onTap: () => setState(() => _mode = ImportMode.merge),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _ModeChip(
                        label: 'REMPLACER LE PLAN',
                        selected: _mode == ImportMode.replace,
                        onTap: () => setState(() => _mode = ImportMode.replace),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _mode == ImportMode.merge
                      ? 'Les séances du fichier s\'ajoutent au plan. Une séance existante le même jour avec le même titre est mise à jour.'
                      : 'Le plan actuel est entièrement remplacé par le contenu du fichier.',
                  style: AppText.sans(size: 12, color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: _busy ? 'Patientez…' : 'Choisir un fichier CSV',
                  onTap: _busy ? null : _import,
                ),
              ],
            ),
          ),
          const SectionLabel('FORMAT ATTENDU'),
          AppCard(
            color: AppColors.cardDeep,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SessionCsvCodec.header.join(' ; '),
                  style: AppText.mono(size: 10, color: AppColors.textSoft, height: 1.7),
                ),
                const HairLine(vertical: 12),
                _FormatLine('date', 'AAAA-MM-JJ (ou JJ/MM/AAAA)'),
                _FormatLine('sport', Sport.values.map((sport) => sport.code).join(' · ')),
                _FormatLine('titre', 'obligatoire · les autres colonnes sont facultatives'),
                _FormatLine('duree_min', 'minutes entières · distance_km avec . ou ,'),
                _FormatLine('tags', 'séparés par | · faite : oui / non'),
                _FormatLine('structure', 'titre~détail~minutes~L/M/H, blocs séparés par |'),
                const HairLine(vertical: 12),
                Text(
                  '2026-09-14;CAP;Fractionné 8 × 400 m;Piste · récup 90″;55;11;3′20 /km;Z4 · 172;8;18h30;Stade;PISTE|VMA;Échauffement~Footing~20~M | 8 × 400 m~@ 3′20/km~25~H;non;',
                  style: AppText.mono(size: 9, color: AppColors.mutedDark, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Séparateur « ; » (Excel français) ou « , » détecté automatiquement.\nL\'export s\'ouvre directement dans Excel ou Numbers.',
            style: AppText.mono(size: 10, color: AppColors.dim, height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.detail,
    required this.action,
    required this.onTap,
    this.enabled = true,
    this.filled = true,
  });

  final String title;
  final String detail;
  final String action;
  final VoidCallback onTap;
  final bool enabled;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      onTap: enabled ? onTap : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.sans(size: 14, weight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(detail, style: AppText.mono(size: 9.5, color: AppColors.mutedDark)),
              ],
            ),
          ),
          Opacity(
            opacity: enabled ? 1 : .4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: filled ? AppColors.text : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.borderDashed),
              ),
              child: Text(
                action,
                style: AppText.mono(
                  size: 10,
                  letterSpacingEm: .06,
                  color: filled ? AppColors.onLight : AppColors.textPill,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.text : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Text(
          label,
          style: AppText.mono(
            size: 9.5,
            color: selected ? AppColors.onLight : AppColors.textFilter,
          ),
        ),
      ),
    );
  }
}

class _FormatLine extends StatelessWidget {
  const _FormatLine(this.key_, this.value);

  final String key_;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(key_, style: AppText.mono(size: 10, color: AppColors.text)),
          ),
          Expanded(
            child: Text(value, style: AppText.mono(size: 10, color: AppColors.muted, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
