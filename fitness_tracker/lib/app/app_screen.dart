import 'package:flutter/material.dart';

import 'app_shell.dart';

/// Les cinq onglets de la barre du bas.
enum AppTab {
  home('Accueil', Icons.home_outlined),
  plan('Plan', Icons.calendar_today_outlined),
  history('Activités', Icons.show_chart),
  body('Corps', Icons.accessibility_new_outlined),
  stats('Stats', Icons.bar_chart);

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
  /// Empile un écran de détail (retour possible) ; un écran racine change d'onglet.
  Future<T?> goTo<T>(AppScreen screen, {Object? arguments}) async {
    if (screen == AppScreen.rootOf(screen.tab)) {
      switchTab(screen.tab);
      return null;
    }
    return Navigator.of(this).pushNamed<T>(screen.route, arguments: arguments);
  }

  /// Affiche la racine d'un onglet en refermant les écrans de détail.
  void switchTab(AppTab tab) => AppShell.switchTab(this, tab);
}
