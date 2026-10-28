import 'package:flutter/material.dart';

import 'app_shell.dart';

/// Les cinq onglets de la barre du bas.
/// Ordre de la barre : l'accueil au centre, le plan et les activités (les plus
/// utilisés) de part et d'autre, le corps et les stats aux extrémités.
enum AppTab {
  body('Corps', Icons.monitor_weight_outlined, Icons.monitor_weight),
  plan('Plan', Icons.event_note_outlined, Icons.event_note),
  home('Accueil', Icons.home_outlined, Icons.home_rounded),
  history('Activités', Icons.route_outlined, Icons.route),
  stats('Stats', Icons.insights_outlined, Icons.insights);

  const AppTab(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
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
