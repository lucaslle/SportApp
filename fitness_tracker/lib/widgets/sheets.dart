import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ouvre un panneau qui monte du bas, remonté au-dessus du clavier.
Future<T?> showAppSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: builder(sheetContext),
    ),
  );
}

/// Mise en page d'un panneau de saisie ou de confirmation : poignée, titre,
/// contenu, puis les actions côte à côte (la dernière est l'action principale).
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({super.key, required this.title, this.content, this.actions = const []});

  final Widget title;
  final Widget? content;
  final List<SheetAction> actions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: AppColors.borderDashed, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          DefaultTextStyle.merge(style: AppText.display(size: 26), child: title),
          if (content != null) ...[const SizedBox(height: 16), content!],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: actions[i]..primary = i == actions.length - 1),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Bouton d'un [SheetScaffold] : plein pour l'action principale (rouge si elle
/// détruit quelque chose), bordé pour les autres.
// ignore: must_be_immutable
class SheetAction extends StatelessWidget {
  SheetAction({super.key, required this.label, required this.onPressed, this.destructive = false});

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  /// Fixé par [SheetScaffold] selon la position du bouton.
  bool primary = false;

  @override
  Widget build(BuildContext context) {
    final style = AppText.sans(size: 15, weight: FontWeight.w600);
    if (!primary) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: style.copyWith(color: AppColors.text)),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: destructive ? const Color(0xFFDC2626) : AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: style.copyWith(color: destructive ? Colors.white : AppColors.onAccent)),
    );
  }
}

/// Demande une confirmation avant une suppression.
Future<bool> confirmDelete(BuildContext context, {required String title, required String detail}) async {
  final confirmed = await showAppSheet<bool>(
    context: context,
    builder: (sheetContext) => SheetScaffold(
      title: Text(title),
      content: Text(detail, style: AppText.sans(size: 14, color: AppColors.muted)),
      actions: [
        SheetAction(label: 'Annuler', onPressed: () => Navigator.of(sheetContext).pop(false)),
        SheetAction(label: 'Supprimer', destructive: true, onPressed: () => Navigator.of(sheetContext).pop(true)),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Fond rouge révélé en glissant une ligne vers la gauche pour la supprimer.
Widget swipeToDelete({
  required Key key,
  required Widget child,
  required Future<bool> Function() confirm,
  required VoidCallback onDeleted,
}) {
  return Dismissible(
    key: key,
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) => confirm(),
    onDismissed: (_) => onDeleted(),
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    ),
    child: child,
  );
}
