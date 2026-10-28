import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Courbes de niveau façon carte topo : le motif de fond de l'app.
class TopoPainter extends CustomPainter {
  const TopoPainter({required this.color, this.seed = 0});

  final Color color;

  /// Décale les reliefs pour que deux surfaces n'aient pas le même dessin.
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final random = math.Random(seed);
    final unit = math.max(size.width, 220.0);
    // Deux sommets, chacun entouré de lignes de niveau déformées.
    for (var peak = 0; peak < 2; peak++) {
      final center = Offset(
        size.width * (peak == 0 ? .82 : .12) + random.nextDouble() * 30,
        size.height * (peak == 0 ? .18 : .9) + random.nextDouble() * 30,
      );
      final phase = random.nextDouble() * math.pi * 2;
      for (var ring = 1; ring <= 9; ring++) {
        final radius = unit * .07 * ring;
        final path = Path();
        for (var step = 0; step <= 72; step++) {
          final angle = step / 72 * math.pi * 2;
          final wobble = 1 +
              .13 * math.sin(3 * angle + phase + ring * .25) +
              .07 * math.sin(5 * angle - phase * 1.7 + ring * .4);
          final point = center + Offset(math.cos(angle), math.sin(angle) * .78) * radius * wobble;
          step == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(TopoPainter old) => old.color != color || old.seed != seed;
}

/// Motif topo discret en haut des écrans, qui s'efface vers le bas.
class TopoBackdrop extends StatelessWidget {
  const TopoBackdrop({super.key, this.height = 340});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.transparent],
          ).createShader(rect),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: TopoPainter(color: AppColors.accentText.withValues(alpha: AppColors.palette.isDark ? .10 : .12)),
            ),
          ),
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
