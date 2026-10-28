import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_screen.dart';
import '../theme/app_theme.dart';

/// Barre d'onglets flottante translucide : cinq emplacements fixes, icône et nom
/// toujours visibles, pastille derrière l'icône de l'onglet actif.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.active, required this.onSelect});

  final AppTab active;
  final ValueChanged<AppTab> onSelect;

  void _select(AppTab tab) {
    if (tab != active) HapticFeedback.selectionClick();
    onSelect(tab);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.text.withValues(alpha: .08)),
          ),
          child: Row(
            children: [
              for (final tab in AppTab.values)
                Expanded(child: _TabButton(tab: tab, selected: tab == active, onTap: () => _select(tab))),
            ],
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

  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentText : AppColors.dim;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // La pastille s'élargit depuis le centre, sans déplacer les onglets voisins.
            AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOutCubic,
              width: selected ? 56 : 32,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent.withValues(alpha: .18) : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(selected ? tab.activeIcon : tab.icon, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            // Réduit le nom plutôt que de le couper sur les écrans étroits.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tab.label,
                maxLines: 1,
                style: AppText.sans(
                  size: 11,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.accentText : AppColors.muted,
                ),
              ),
            ),
          ],
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
