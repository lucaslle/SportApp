import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Faisceaux de lignes fines et parallèles en épingle, comme le virage d'une piste.
class TrackPainter extends CustomPainter {
  const TrackPainter({required this.color});

  final Color color;

  static const _lines = 16;
  static const _gap = 4.2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Deux virages parallèles qui ne se croisent pas : un grand à droite, un petit à gauche.
    _ribbon(canvas, paint, Offset(size.width * .74, 96), .5, 54);
    _ribbon(canvas, paint, Offset(size.width * .12, 270), math.pi + .5, 30);
  }

  /// Lignes droites qui font demi-tour autour de [bend], le faisceau orienté de [angle] radians.
  void _ribbon(Canvas canvas, Paint paint, Offset bend, double angle, double inner) {
    canvas.save();
    canvas.translate(bend.dx, bend.dy);
    canvas.rotate(angle);
    for (var line = 0; line < _lines; line++) {
      final radius = inner + line * _gap;
      canvas.drawPath(
        Path()
          ..moveTo(-900, -radius)
          ..lineTo(0, -radius)
          ..arcToPoint(Offset(0, radius), radius: Radius.circular(radius))
          ..lineTo(-900, radius),
        paint,
      );
    }
    canvas.restore();
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
        // Les faisceaux débordent du cadre : on les coupe au bord du fond.
        child: ClipRect(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, .5, 1],
            ).createShader(rect),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(.8, -1),
                      radius: 1.5,
                      colors: [
                        AppColors.accent.withValues(alpha: dark ? .38 : .34),
                        AppColors.accent.withValues(alpha: 0)
                      ],
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: CustomPaint(
                    painter: TrackPainter(color: AppColors.accentText.withValues(alpha: dark ? .45 : .4)),
                  ),
                ),
              ],
            ),
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
