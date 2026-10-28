import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_screen.dart';
import '../theme/app_theme.dart';

/// Barre d'onglets flottante translucide : icônes seules, l'onglet actif s'étire
/// en pastille avec son nom.
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
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.text.withValues(alpha: .08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final tab in AppTab.values)
                // Seule la pastille active peut rétrécir (nom coupé) sur un écran très étroit.
                Flexible(
                  flex: tab == active ? 1 : 0,
                  child: _TabBubble(tab: tab, selected: tab == active, onTap: () => _select(tab)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBubble extends StatelessWidget {
  const _TabBubble({required this.tab, required this.selected, required this.onTap});

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentText : AppColors.dim;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: .16) : Colors.transparent,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? tab.activeIcon : tab.icon, size: 23, color: color),
              // Le nom se déroule à côté de l'icône de l'onglet actif.
              Flexible(
                child: AnimatedSize(
                  duration: _duration,
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 7),
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: AppText.sans(size: 14, weight: FontWeight.w700, color: color),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
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
