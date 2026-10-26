import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/app_screen.dart';
import '../theme/app_theme.dart';

/// Barre d'onglets flottante translucide, en bas de l'écran.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.active, required this.onSelect});

  final AppTab active;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 68,
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.text.withValues(alpha: .1)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 34,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              for (final tab in AppTab.values)
                Expanded(
                  child: _TabButton(
                    tab: tab,
                    selected: tab == active,
                    onTap: () => onSelect(tab),
                  ),
                ),
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

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.text : AppColors.dim;
    final labelColor = selected ? AppColors.text : AppColors.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 160),
        height: 58,
        decoration: BoxDecoration(
          color: selected ? AppColors.text.withValues(alpha: .13) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, size: 19, color: iconColor),
            SizedBox(height: 5),
            // Réduit le libellé plutôt que de le couper sur les écrans étroits.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tab.label,
                maxLines: 1,
                style: AppText.mono(size: 8, color: labelColor, letterSpacingEm: .06),
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
