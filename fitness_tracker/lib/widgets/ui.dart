import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Espace réservé sous le contenu pour la barre d'onglets flottante.
const double kTabBarInset = 122;

/// Petit libellé mono majuscules espacées.
class Eyebrow extends StatelessWidget {
  const Eyebrow(
    this.text, {
    super.key,
    this.size = 10,
    this.color = AppColors.mutedDark,
    this.spacingEm = .2,
    this.align,
  });

  final String text;
  final double size;
  final Color color;
  final double spacingEm;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: AppText.eyebrow(size: size, color: color, letterSpacingEm: spacingEm),
    );
  }
}

/// Carte sombre bordée, le conteneur de base de la maquette.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 14,
    this.color = AppColors.card,
    this.borderColor = AppColors.border,
    this.onTap,
    this.margin,
  });

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
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: box);
  }
}

/// Pastille de tag (CAP, PISTE, VMA…).
class TagPill extends StatelessWidget {
  const TagPill(
    this.text, {
    super.key,
    this.size = 9,
    this.color = AppColors.textPill,
    this.background = Colors.transparent,
    this.borderColor = AppColors.borderDashed,
    this.radius = 99,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.spacingEm = .12,
  });

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
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.mono(size: valueSize, weight: FontWeight.w700),
          ),
          if (sub != null) ...[
            const SizedBox(height: 3),
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
                Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
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
  const DashedBox({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(15),
    this.radius = 14,
    this.color = AppColors.borderDashed,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: color, radius: radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(.5);
    final path = Path()..addRRect(rect);
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}

/// Bouton plein blanc (action principale).
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
          color: light ? AppColors.text : AppColors.onLight,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          label,
          style: AppText.sans(
            size: 14,
            weight: FontWeight.w600,
            color: light ? AppColors.onLight : AppColors.text,
          ),
        ),
      ),
    );
  }
}

/// Bouton bordé, texte ou icône (‹ › MOIS CSV…).
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height = 36,
    this.radius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 11),
    this.borderColor = AppColors.borderMid,
    this.background = Colors.transparent,
  });

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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text('← $label', style: AppText.mono(size: 11, color: AppColors.muted)),
      ),
    );
  }
}

/// Titre de section mono avec marges verticales.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.top = 22, this.bottom = 10, this.trailing});

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
        children: [Eyebrow(text), if (trailing != null) trailing!],
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
        const SizedBox(height: 5),
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
        duration: const Duration(milliseconds: 160),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
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
  const ProgressBar({
    super.key,
    required this.fraction,
    this.color = AppColors.text,
    this.trackColor = AppColors.track,
    this.height = 6,
  });

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
  const BarItem({required this.label, required this.fraction, this.color = AppColors.text});

  final String label;
  final double fraction;
  final Color color;
}

/// Histogramme vertical à colonnes (semaine, charge, zones FC).
class BarColumnChart extends StatelessWidget {
  const BarColumnChart({
    super.key,
    required this.items,
    this.height = 82,
    this.gap = 8,
    this.labelSize = 9,
    this.labelColor = AppColors.mutedDark,
    this.minFraction = .04,
  });

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
                  const SizedBox(height: 7),
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
    this.padding = const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
  });

  final Widget leading;
  final Widget trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
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
