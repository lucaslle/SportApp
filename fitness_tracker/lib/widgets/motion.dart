import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Couloirs d'une piste d'athlé (ligne droite puis virage), numérotés, avec la ligne de départ.
class TrackPainter extends CustomPainter {
  const TrackPainter({required this.color});

  final Color color;

  static const _lanes = 6;
  static const _laneWidth = 15.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final center = Offset(size.width * .62, 150);
    const inner = 70.0;
    for (var lane = 0; lane <= _lanes; lane++) {
      final radius = inner + lane * _laneWidth;
      final path = Path()
        ..moveTo(-10, center.dy - radius)
        ..lineTo(center.dx, center.dy - radius)
        ..arcToPoint(Offset(center.dx, center.dy + radius), radius: Radius.circular(radius))
        ..lineTo(-10, center.dy + radius);
      canvas.drawPath(path, paint);
    }
    // Ligne de départ et numéros de couloir sur la ligne droite du haut.
    final startX = size.width * .22;
    final top = center.dy - inner - _lanes * _laneWidth;
    canvas.drawLine(Offset(startX, top), Offset(startX, center.dy - inner), paint..strokeWidth = 2.4);
    for (var lane = 0; lane < _lanes; lane++) {
      final label = TextPainter(
        text: TextSpan(
          text: '${_lanes - lane}',
          style: AppText.display(size: 11, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(startX - label.width - 6, top + lane * _laneWidth + (_laneWidth - label.height) / 2));
    }
  }

  @override
  bool shouldRepaint(TrackPainter old) => old.color != color;
}

/// Haut des écrans : halo de la couleur d'accent et piste d'athlé discrète, qui s'effacent vers le bas.
class SportBackdrop extends StatelessWidget {
  const SportBackdrop({super.key, this.height = 360});

  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.palette.isDark;
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, .45, 1],
          ).createShader(rect),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(.9, -1.1),
                    radius: 1.1,
                    colors: [AppColors.accent.withValues(alpha: dark ? .22 : .2), AppColors.accent.withValues(alpha: 0)],
                  ),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  painter: TrackPainter(color: AppColors.accentText.withValues(alpha: dark ? .14 : .16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numéro de dossard géant en filigrane, détouré.
class BibNumber extends StatelessWidget {
  const BibNumber(this.number, {super.key, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        '$number',
        maxLines: 1,
        softWrap: false,
        style: AppText.display(size: 170).copyWith(
          height: .9,
          fontWeight: FontWeight.w800,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color,
        ),
      ),
    );
  }
}

/// Fait apparaître une liste d'éléments les uns après les autres (fondu et glissé).
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({super.key, required this.children});

  final List<Widget> children;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  // Au-delà, les éléments sont hors écran : inutile de les retarder.
  static const _staggered = 8;
  static const _step = .07;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 760));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.children.length; i++) _reveal(i, widget.children[i]),
      ],
    );
  }

  Widget _reveal(int index, Widget child) {
    final start = math.min(index, _staggered) * _step;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, math.min(start + .45, 1), curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .08), end: Offset.zero).animate(curve),
        child: child,
      ),
    );
  }
}

/// Léger enfoncement au toucher.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? .97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Valeur de 0 à 1 qui monte à l'affichage, pour faire pousser barres et courbes.
class GrowIn extends StatelessWidget {
  const GrowIn({super.key, required this.builder, this.duration = const Duration(milliseconds: 900)});

  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => builder(context, t),
    );
  }
}
