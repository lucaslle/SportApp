import 'package:flutter/material.dart';

/// Les cinq onglets de la barre du bas.
enum AppTab {
  home('ACCUEIL', Icons.home_outlined),
  plan('PLAN', Icons.calendar_today_outlined),
  history('ACTIVITÉS', Icons.show_chart),
  body('CORPS', Icons.accessibility_new_outlined),
  stats('STATS', Icons.bar_chart);

  const AppTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Les onze écrans de la maquette, avec l'onglet qu'ils mettent en avant.
enum AppScreen {
  home('/home', AppTab.home, 'Aujourd\'hui'),
  plan('/plan', AppTab.plan, 'Plan de la semaine'),
  calendar('/calendar', AppTab.plan, 'Calendrier & courses'),
  session('/session', AppTab.plan, 'Détail de séance'),
  body('/body', AppTab.body, 'Poids & composition'),
  history('/history', AppTab.history, 'Historique des sorties'),
  activity('/activity', AppTab.history, 'Détail sortie GPS'),
  stats('/stats', AppTab.stats, 'Charge d\'entraînement'),
  goals('/goals', AppTab.stats, 'Objectifs & records');

  const AppScreen(this.route, this.tab, this.label);

  final String route;
  final AppTab tab;
  final String label;

  static AppScreen? fromRoute(String? route) {
    for (final screen in AppScreen.values) {
      if (screen.route == route) return screen;
    }
    return null;
  }

  /// Écran racine de chaque onglet.
  static AppScreen rootOf(AppTab tab) => switch (tab) {
        AppTab.home => AppScreen.home,
        AppTab.plan => AppScreen.plan,
        AppTab.history => AppScreen.history,
        AppTab.body => AppScreen.body,
        AppTab.stats => AppScreen.stats,
      };
}

/// Raccourcis de navigation entre écrans.
extension AppNavigation on BuildContext {
  /// Empile un écran (retour possible).
  Future<T?> goTo<T>(AppScreen screen, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(screen.route, arguments: arguments);
  }

  /// Remplace toute la pile par la racine d'un onglet.
  void switchTab(AppTab tab) {
    Navigator.of(this).pushNamedAndRemoveUntil(AppScreen.rootOf(tab).route, (_) => false);
  }
}
