import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_screen.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

/// Barre d'onglets flottante translucide : encoche au centre pour le bouton rond de l'accueil,
/// pastille qui glisse sous l'onglet actif.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.active, required this.onSelect});

  final AppTab active;
  final ValueChanged<AppTab> onSelect;

  static const _barHeight = 64.0;
  static const _homeSize = 58.0;

  /// Le bouton central est centré sur le bord haut de la barre.
  static const _lift = _homeSize / 2;

  void _select(AppTab tab) {
    if (tab != active) HapticFeedback.selectionClick();
    onSelect(tab);
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.palette.isDark;
    // La zone englobe la barre et le haut du bouton central pour qu'il reste touchable.
    return SizedBox(
      height: _barHeight + _lift,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            height: _barHeight,
            child: CustomPaint(
              painter: const _NotchShadow(),
              foregroundPainter: _NotchBorder(
                color: AppColors.text.withValues(alpha: dark ? .12 : .08),
              ),
              child: ClipPath(
                clipper: const _NotchClipper(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.glass,
                      // Reflet léger en haut, comme une plaque de verre.
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.alphaBlend(Colors.white.withValues(alpha: dark ? .06 : .5), AppColors.glass),
                          AppColors.glass,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: LayoutBuilder(
                        builder: (context, constraints) => Stack(
                          children: [
                            _Indicator(active: active, slotWidth: constraints.maxWidth / AppTab.values.length),
                            Row(
                              children: [
                                for (final tab in AppTab.values)
                                  Expanded(
                                    child: tab == AppTab.home
                                        ? const SizedBox.shrink()
                                        : _TabButton(tab: tab, selected: tab == active, onTap: () => _select(tab)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _HomeButton(selected: active == AppTab.home, onTap: () => _select(AppTab.home)),
          ),
        ],
      ),
    );
  }
}

/// Contour de la barre : pilule creusée d'une encoche ronde au centre du bord haut.
Path _notchedBar(Size size) {
  final bar = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2)));
  final notch = Path()
    ..addOval(Rect.fromCircle(center: Offset(size.width / 2, 0), radius: GlassTabBar._homeSize / 2 + 7));
  return Path.combine(PathOperation.difference, bar, notch);
}

class _NotchClipper extends CustomClipper<Path> {
  const _NotchClipper();

  @override
  Path getClip(Size size) => _notchedBar(size);

  @override
  bool shouldReclip(_NotchClipper oldClipper) => false;
}

class _NotchBorder extends CustomPainter {
  const _NotchBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _notchedBar(size),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_NotchBorder old) => old.color != color;
}

class _NotchShadow extends CustomPainter {
  const _NotchShadow();

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawShadow(_notchedBar(size), Colors.black.withValues(alpha: .35), 8, false);

  @override
  bool shouldRepaint(_NotchShadow old) => false;
}

/// Pastille teintée qui glisse sous l'onglet actif ; elle s'efface sous le bouton central.
class _Indicator extends StatelessWidget {
  const _Indicator({required this.active, required this.slotWidth});

  final AppTab active;
  final double slotWidth;

  @override
  Widget build(BuildContext context) {
    final onHome = active == AppTab.home;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      left: active.index * slotWidth + 4,
      top: 8,
      width: slotWidth - 8,
      bottom: 8,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onHome ? 0 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.tab, required this.selected, required this.onTap});

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                selected ? tab.activeIcon : tab.icon,
                size: 22,
                color: selected ? AppColors.accentText : AppColors.dim,
              ),
            ),
            const SizedBox(height: 4),
            _Label(tab, selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.tab, {required this.selected});

  final AppTab tab;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    // Réduit le libellé plutôt que de le couper sur les écrans étroits.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        tab.label,
        maxLines: 1,
        style: AppText.sans(
          size: 10,
          weight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.accentText : AppColors.muted,
        ),
      ),
    );
  }
}

/// Accueil : rond plein de la couleur d'accent, posé au-dessus de la barre.
class _HomeButton extends StatelessWidget {
  const _HomeButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: AppTab.home.label,
      child: GestureDetector(
        onTap: onTap,
        child: PressScale(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: GlassTabBar._homeSize,
            height: GlassTabBar._homeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Dégradé de la couleur d'accent, plus clair en haut à gauche pour donner du volume.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(AppColors.accent, Colors.white, .22)!,
                  AppColors.accent,
                  Color.lerp(AppColors.accent, Colors.black, .12)!,
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .25)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: selected ? .45 : .25),
                  blurRadius: selected ? 20 : 14,
                  spreadRadius: -3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                selected ? AppTab.home.activeIcon : AppTab.home.icon,
                size: 28,
                color: AppColors.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dégradé qui fond le contenu sous la barre d'onglets.
class BottomFade extends StatelessWidget {
  const BottomFade({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: [0, .42, 1],
            colors: [
              AppColors.background.withValues(alpha: .96),
              AppColors.background.withValues(alpha: .96),
              AppColors.background.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
