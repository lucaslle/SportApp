import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/app_screen.dart';
import '../theme/app_theme.dart';

/// Barre d'onglets flottante translucide, avec l'accueil en bouton rond surélevé au centre.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.active, required this.onSelect});

  final AppTab active;
  final ValueChanged<AppTab> onSelect;

  static const _barHeight = 64.0;
  static const _homeSize = 60.0;

  @override
  Widget build(BuildContext context) {
    // Le bouton central dépasse de la barre : la zone englobe les deux pour rester touchable.
    return SizedBox(
      height: _barHeight + 20,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_barHeight / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: _barHeight,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(_barHeight / 2),
                  border: Border.all(color: AppColors.text.withValues(alpha: .1)),
                ),
                child: Row(
                  children: [
                    for (final tab in AppTab.values)
                      Expanded(
                        child: tab == AppTab.home
                            // Place du bouton central, avec son libellé sous le rond.
                            ? Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 13),
                                  child: _Label(tab, selected: tab == active),
                                ),
                              )
                            : _TabButton(tab: tab, selected: tab == active, onTap: () => onSelect(tab)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _HomeButton(selected: active == AppTab.home, onTap: () => onSelect(AppTab.home)),
          ),
        ],
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
            const SizedBox(height: 3),
            // Petit trait sous l'onglet actif.
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: selected ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2)),
            ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: GlassTabBar._homeSize,
          height: GlassTabBar._homeSize,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            // L'anneau du fond détache le rond de la barre ; plus marqué quand l'accueil est affiché.
            border: Border.all(color: AppColors.background, width: selected ? 4 : 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: selected ? .32 : .18),
                blurRadius: selected ? 22 : 14,
                spreadRadius: -4,
                offset: const Offset(0, 4),
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
