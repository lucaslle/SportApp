import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workout_session.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Compteur de repos d'un exercice : séries à cocher une à une, repos réglable
/// entre chaque série, vibration à la fin du repos.
Future<void> showRestTimer(BuildContext context, SessionBlock block) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    backgroundColor: AppColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      side: BorderSide(color: AppColors.border),
    ),
    builder: (_) => _RestTimerSheet(block: block),
  );
}

/// Séries lues dans l'exercice ("3 × 10", "4x8"), 3 par défaut.
int setsOf(SessionBlock block) {
  final match = RegExp(r'(\d+)\s*[×xX]\s*\d+').firstMatch('${block.title} ${block.detail}');
  final sets = int.tryParse(match?.group(1) ?? '');
  return sets == null || sets < 1 || sets > 20 ? 3 : sets;
}

/// Repos lu dans l'exercice ("récup 90″", "repos 2′", "récup 1'30"), 90 s par défaut.
int restSecondsOf(SessionBlock block) {
  final match = RegExp(r"(?:récup|repos)\D{0,3}(\d+)\s*([″\x22s]|[′']\s*(\d{1,2})?|min)", caseSensitive: false)
      .firstMatch('${block.title} ${block.detail}');
  if (match == null) return 90;
  final value = int.parse(match.group(1)!);
  final unit = match.group(2)!;
  if (unit.startsWith('″') || unit == '"' || unit == 's') return value.clamp(5, 900);
  return (value * 60 + (int.tryParse(match.group(3) ?? '') ?? 0)).clamp(5, 900);
}

String _clock(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

class _RestTimerSheet extends StatefulWidget {
  const _RestTimerSheet({required this.block});

  final SessionBlock block;

  @override
  State<_RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<_RestTimerSheet> with WidgetsBindingObserver {
  static const List<int> _presets = [30, 60, 90, 120, 180];

  late int _sets = setsOf(widget.block);
  late int _rest = restSecondsOf(widget.block);

  /// Séries déjà terminées.
  int _done = 0;

  /// Secondes de repos restantes ; null hors repos.
  int? _left;

  /// Heure de fin du repos, pour recaler le décompte au retour de l'arrière-plan.
  DateTime _restEnd = DateTime(0);

  /// Durée totale du repos en cours, rallonges comprises, pour l'anneau.
  int _restTotal = 1;
  Timer? _ticker;

  bool get _finished => _done >= _sets;

  int get _remaining => _left ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _left == null) return;
    final left = (_restEnd.difference(DateTime.now()).inMilliseconds / 1000).ceil();
    if (left <= 0) {
      _endRest(alert: true);
    } else {
      setState(() => _left = left);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  void _completeSet() {
    setState(() => _done++);
    if (_finished) {
      HapticFeedback.mediumImpact();
      return;
    }
    _startRest(_rest);
  }

  void _startRest(int seconds) {
    _ticker?.cancel();
    setState(() {
      _left = seconds;
      _restTotal = seconds;
      _restEnd = DateTime.now().add(Duration(seconds: seconds));
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 1) {
        setState(() => _left = _remaining - 1);
        return;
      }
      _endRest(alert: true);
    });
  }

  void _endRest({required bool alert}) {
    _ticker?.cancel();
    setState(() => _left = null);
    if (!alert) return;
    SystemSound.play(SystemSoundType.alert);
    // Trois vibrations : le téléphone est souvent posé ou dans la poche.
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 350 * i), HapticFeedback.heavyImpact);
    }
  }

  void _addTime(int seconds) {
    if (_left == null) return;
    setState(() {
      _left = _remaining + seconds;
      _restTotal += seconds;
      _restEnd = _restEnd.add(Duration(seconds: seconds));
    });
  }

  @override
  Widget build(BuildContext context) {
    final resting = _left != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ScreenHeader(eyebrow: 'REPOS ENTRE LES SÉRIES', title: widget.block.title, titleSize: 22),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, size: 26, color: AppColors.text),
              ),
            ],
          ),
          if (widget.block.detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.block.detail, style: AppText.sans(size: 13, color: AppColors.muted)),
            ),
          const SizedBox(height: 20),
          _SetDots(total: _sets, done: _done),
          const SizedBox(height: 20),
          Center(child: resting ? _countdown() : _status()),
          const SizedBox(height: 22),
          if (resting)
            Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    height: 52,
                    borderColor: AppColors.borderStrong,
                    onTap: () => _addTime(15),
                    child: Text('+15 s', style: AppText.sans(size: 15, weight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(label: 'Passer le repos', onTap: () => _endRest(alert: false)),
                ),
              ],
            )
          else if (!_finished)
            PrimaryButton(
              label: _done + 1 == _sets ? 'Dernière série terminée' : 'Série ${_done + 1} terminée · repos',
              onTap: _completeSet,
            )
          else
            PrimaryButton(label: 'Fermer', onTap: () => Navigator.of(context).pop()),
          const SizedBox(height: 26),
          Eyebrow('SÉRIES', spacingEm: .14),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepButton(icon: Icons.remove, onTap: _sets > 1 ? () => setState(() => _sets--) : null),
              Expanded(
                child:
                    Text('$_sets', textAlign: TextAlign.center, style: AppText.mono(size: 22, weight: FontWeight.w700)),
              ),
              _StepButton(icon: Icons.add, onTap: _sets < 20 ? () => setState(() => _sets++) : null),
            ],
          ),
          const SizedBox(height: 18),
          Eyebrow('DURÉE DU REPOS', spacingEm: .14),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepButton(icon: Icons.remove, onTap: _rest > 15 ? () => setState(() => _rest -= 15) : null),
              Expanded(
                child: Text(_clock(_rest),
                    textAlign: TextAlign.center, style: AppText.mono(size: 22, weight: FontWeight.w700)),
              ),
              _StepButton(icon: Icons.add, onTap: _rest < 600 ? () => setState(() => _rest += 15) : null),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _presets)
                ChoiceChip(
                  label: Text(preset < 60 ? '$preset s' : _clock(preset), style: AppText.mono(size: 12)),
                  selected: _rest == preset,
                  onSelected: (_) => setState(() => _rest = preset),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countdown() {
    final remaining = _remaining;
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (remaining / _restTotal).clamp(0, 1),
              strokeWidth: 8,
              color: AppColors.accent,
              backgroundColor: AppColors.track,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_clock(remaining), style: AppText.mono(size: 48, weight: FontWeight.w700)),
              Text('avant la série ${_done + 1}', style: AppText.sans(size: 13, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _status() {
    return Column(
      children: [
        Text(
          _finished ? 'Exercice terminé' : 'Série ${_done + 1} sur $_sets',
          style: AppText.sans(size: 26, weight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          _finished ? '$_sets séries faites' : 'C\'est parti',
          style: AppText.sans(size: 14, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Une pastille par série : pleine quand elle est faite.
class _SetDots extends StatelessWidget {
  const _SetDots({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: i < done ? AppColors.text : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: i < done ? AppColors.text : AppColors.borderStrong, width: 2),
            ),
            child: Text(
              '${i + 1}',
              style: AppText.mono(
                  size: 11, weight: FontWeight.w700, color: i < done ? AppColors.onLight : AppColors.muted),
            ),
          ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onTap,
      iconSize: 24,
      style: IconButton.styleFrom(minimumSize: const Size(52, 52), side: BorderSide(color: AppColors.borderStrong)),
      icon: Icon(icon, color: onTap == null ? AppColors.dimmer : AppColors.text),
    );
  }
}
