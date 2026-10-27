import 'package:flutter/material.dart';

import '../models/sport.dart';
import '../theme/app_theme.dart';
import '../theme/sport_colors.dart';
import '../utils/typography.dart';

/// Espace réservé sous le contenu pour la barre d'onglets flottante.
const double kTabBarInset = 122;

/// Petit libellé mono majuscules espacées.
class Eyebrow extends StatelessWidget {
  Eyebrow(
    this.text, {
    super.key,
    this.size = 10,
    Color? color,
    this.spacingEm = .2,
    this.align,
  }) : color = color ?? AppColors.mutedDark;

  final String text;
  final double size;
  final Color color;
  final double spacingEm;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    // Libellé discret en casse de phrase : les majuscules espacées faisaient daté.
    return Text(
      sentenceCase(text),
      textAlign: align,
      style: AppText.sans(size: size + 2.5, weight: FontWeight.w500, color: color),
    );
  }
}

/// Carte sombre bordée, le conteneur de base de la maquette.
class AppCard extends StatelessWidget {
  AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    Color? color,
    Color? borderColor,
    this.onTap,
    this.margin,
  }) : color = color ?? AppColors.card, borderColor = borderColor ?? AppColors.border;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor.withValues(alpha: AppColors.palette.isDark ? .7 : .5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.palette.isDark ? .18 : .05),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: box),
    );
  }
}

/// Pastille de tag (CAP, PISTE, VMA…).
class TagPill extends StatelessWidget {
  TagPill(
    this.text, {
    super.key,
    this.size = 9,
    Color? color,
    this.background = Colors.transparent,
    Color? borderColor,
    this.radius = 99,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.spacingEm = .12,
  }) : color = color ?? AppColors.textPill, borderColor = borderColor ?? AppColors.borderDashed;

  final String text;
  final double size;
  final Color color;
  final Color background;
  final Color borderColor;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double spacingEm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.mono(size: size, color: color, letterSpacingEm: spacingEm),
      ),
    );
  }
}

/// Tuile chiffrée : petit libellé + valeur mono en gras.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.valueSize = 19,
    this.padding = const EdgeInsets.all(13),
  });

  final String label;
  final String value;
  final String? sub;
  final double valueSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label, size: 9, spacingEm: .14),
          SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.mono(size: valueSize, weight: FontWeight.w700),
          ),
          if (sub != null) ...[
            SizedBox(height: 3),
            Text(sub!, style: AppText.mono(size: 10, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

/// Grille de tuiles à colonnes égales.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children, this.columns = 3, this.gap = 10});

  final List<Widget> children;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(child: j < slice.length ? slice[j] : SizedBox()),
              ],
            ],
          ),
        ),
      );
      if (i + columns < children.length) rows.add(SizedBox(height: gap));
    }
    return Column(children: rows);
  }
}

/// Encadré en pointillés (actions secondaires : "Ajouter une séance"…).
class DashedBox extends StatelessWidget {
  DashedBox({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    Color? color,
  }) : color = color ?? AppColors.borderDashed;

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Couleur du contour (gardée pour compatibilité ; le fond est teinté).
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Encadré plein et discret : les pointillés faisaient « maquette ».
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardDeep,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border.withValues(alpha: .6)),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: box),
    );
  }
}

/// Bouton plein (action principale) : orange, ou sombre posé sur une carte orange.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.light = true,
    this.radius = 12,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  final String label;
  final VoidCallback? onTap;
  final bool light;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: light ? AppColors.accent : AppColors.onAccent,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          label,
          style: AppText.sans(
            size: 14,
            weight: FontWeight.w600,
            color: light ? AppColors.onAccent : AppColors.accent,
          ),
        ),
      ),
    );
  }
}

/// Bouton bordé, texte ou icône (‹ › MOIS CSV…).
class OutlineButton extends StatelessWidget {
  OutlineButton({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height = 36,
    this.radius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 11),
    Color? borderColor,
    this.background = Colors.transparent,
  }) : borderColor = borderColor ?? AppColors.borderMid;

  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: width == null ? padding : EdgeInsets.zero,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
        ),
        child: child,
      ),
    );
  }
}

/// Lien de retour "← PLAN".
class BackLink extends StatelessWidget {
  const BackLink(this.label, {super.key, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: 'Retour, $label',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            // Cible tactile d'au moins 48 px de haut.
            padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 26, color: AppColors.text),
                const SizedBox(width: 8),
                Text(sentenceCase(label), style: AppText.sans(size: 15, weight: FontWeight.w600, color: AppColors.textSoft)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Titre de section mono avec marges verticales.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.top = 26, this.bottom = 12, this.trailing});

  final String text;
  final double top;
  final double bottom;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: Text(sentenceCase(text), style: AppText.sans(size: 17, weight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// En-tête d'écran : eyebrow + grand titre, action optionnelle à droite.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
    this.titleSize = 24,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(eyebrow),
        SizedBox(height: 5),
        Text(title, style: AppText.screenTitle(size: titleSize)),
      ],
    );
    if (trailing == null) return text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [Expanded(child: text), trailing!],
    );
  }
}

/// Interrupteur 44×26 noir & blanc.
class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 160),
        width: 44,
        height: 26,
        padding: EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? AppColors.text : AppColors.borderMid,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: value ? AppColors.onLight : AppColors.mutedDark,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Barre de progression fine.
class ProgressBar extends StatelessWidget {
  ProgressBar({
    super.key,
    required this.fraction,
    Color? color,
    Color? trackColor,
    this.height = 6,
  }) : color = color ?? AppColors.text, trackColor = trackColor ?? AppColors.track;

  final double fraction;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: trackColor,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0, 1).toDouble(),
          child: Container(color: color),
        ),
      ),
    );
  }
}

/// Une barre d'un histogramme vertical.
class BarItem {
  BarItem({required this.label, required this.fraction, Color? color}) : color = color ?? AppColors.text;

  final String label;
  final double fraction;
  final Color color;
}

/// Histogramme vertical à colonnes (semaine, charge, zones FC).
class BarColumnChart extends StatelessWidget {
  BarColumnChart({
    super.key,
    required this.items,
    this.height = 82,
    this.gap = 8,
    this.labelSize = 9,
    Color? labelColor,
    this.minFraction = .04,
  }) : labelColor = labelColor ?? AppColors.mutedDark;

  final List<BarItem> items;
  final double height;
  final double gap;
  final double labelSize;
  final Color labelColor;
  final double minFraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: items[i].fraction.clamp(minFraction, 1).toDouble(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: items[i].color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(items[i].label, style: AppText.mono(size: labelSize, color: labelColor)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ligne de liste avec filet inférieur (pesées, records…).
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.leading,
    required this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  });

  final Widget leading;
  final Widget trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // Une petite carte par ligne plutôt qu'un trait de séparation.
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: .5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Flexible(child: leading), trailing],
      ),
    );
  }
}

/// Liste scrollable d'écran avec les marges de la maquette et la réserve
/// pour la barre d'onglets.
class ScreenScroll extends StatelessWidget {
  const ScreenScroll({super.key, required this.children, this.controller});

  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, kTabBarInset),
      children: children,
    );
  }
}

/// Petit séparateur horizontal.
class HairLine extends StatelessWidget {
  const HairLine({super.key, this.vertical = 16});

  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.border,
      margin: EdgeInsets.symmetric(vertical: vertical),
    );
  }
}

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Encadré pointillé affiché quand un écran n'a encore aucune donnée.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.icon = Icons.auto_awesome_outlined});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DashedBox(
      color: AppColors.borderMid,
      padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: .14), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.accentText, size: 26),
          ),
          SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.sans(size: 16, weight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.sans(size: 13, color: AppColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Sélecteur de date aux couleurs de l'application, en français.
Future<DateTime?> pickAppDate(BuildContext context, DateTime initial) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(initial.year - 2),
    lastDate: DateTime(initial.year + 2),
    locale: Locale('fr'),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppColors.text,
          onPrimary: AppColors.onLight,
          surface: AppColors.card,
          onSurface: AppColors.text,
        ),
      ),
      child: child!,
    ),
  );
  return picked == null ? null : DateTime(picked.year, picked.month, picked.day);
}

/// Pastille d'un sport, à sa couleur.
TagPill sportTag(
  Sport sport, {
  double size = 9,
  double radius = 99,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  double spacingEm = .12,
}) {
  return TagPill(
    sport.code,
    size: size,
    radius: radius,
    padding: padding,
    spacingEm: spacingEm,
    color: sport.color,
    borderColor: sport.color.withValues(alpha: .55),
    background: sport.color.withValues(alpha: .12),
  );
}
