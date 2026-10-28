import 'package:flutter/material.dart';

import '../screens/activity_screen.dart';
import '../screens/body_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/plan_screen.dart';
import '../screens/session_screen.dart';
import '../screens/stats_screen.dart';
import '../widgets/glass_tab_bar.dart';
import 'app_screen.dart';

/// Cadre de l'application : les cinq onglets dans des pages qui suivent le doigt,
/// les écrans de détail empilés par-dessus, et la barre d'onglets flottante.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Affiche l'onglet [tab] en refermant les écrans de détail ouverts.
  static void switchTab(BuildContext context, AppTab tab) =>
      context.findAncestorStateOfType<_AppShellState>()?._openTab(tab);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _tabsRoute = Navigator.defaultRouteName;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final PageController _pages = PageController(initialPage: AppTab.home.index);
  late final _ScreenObserver _observer = _ScreenObserver(_onScreenChanged);

  /// Onglet affiché dans les pages.
  int _tab = AppTab.home.index;

  /// Écran de détail ouvert par-dessus les pages ; null quand on est sur les onglets.
  AppScreen? _detail;

  void _onScreenChanged(AppScreen? screen) {
    if (!mounted || screen == _detail) return;
    setState(() => _detail = screen);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _openTab(AppTab tab) {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (!_pages.hasClients) return;
    final distance = (tab.index - _tab).abs();
    if (distance == 0) return;
    // Onglet voisin : on le voit glisser. Plus loin : saut direct, sans défiler les pages entre deux.
    if (distance == 1) {
      _pages.animateToPage(tab.index, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _pages.jumpToPage(tab.index);
    }
  }

  Widget _rootOf(AppTab tab) => switch (tab) {
        AppTab.home => const HomeScreen(),
        AppTab.plan => const PlanScreen(),
        AppTab.history => const HistoryScreen(),
        AppTab.body => const BodyScreen(),
        AppTab.stats => const StatsScreen(),
      };

  Widget _tabPages() {
    return PageView.builder(
      controller: _pages,
      itemCount: AppTab.values.length,
      onPageChanged: (index) => setState(() => _tab = index),
      itemBuilder: (context, index) => AnimatedBuilder(
        animation: _pages,
        child: _rootOf(AppTab.values[index]),
        builder: (context, child) {
          final page = _pages.hasClients && _pages.position.haveDimensions ? _pages.page! : _tab.toDouble();
          // La page qui part recule et pâlit, celle qui arrive reprend sa taille.
          final distance = (page - index).abs().clamp(0.0, 1.0);
          return Opacity(
            opacity: 1 - distance * .4,
            child: Transform.scale(scale: 1 - distance * .08, child: child),
          );
        },
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final screen = AppScreen.fromRoute(settings.name);
    if (screen == null || screen == AppScreen.rootOf(screen.tab)) {
      return PageRouteBuilder<void>(
        settings: const RouteSettings(name: _tabsRoute),
        pageBuilder: (_, __, ___) => _tabPages(),
      );
    }
    final page = switch (screen) {
      AppScreen.calendar => const CalendarScreen(),
      AppScreen.session => SessionScreen(sessionId: settings.arguments as String?),
      AppScreen.activity => ActivityScreen(sessionId: settings.arguments as String?),
      AppScreen.goals => const GoalsScreen(),
      _ => const SizedBox.shrink(),
    };
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: screen.route, arguments: settings.arguments),
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => page,
      // Glissement léger depuis la droite avec fondu, comme les apps natives.
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _navigatorKey.currentState?.maybePop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Navigator(
                key: _navigatorKey,
                initialRoute: _tabsRoute,
                observers: [_observer],
                onGenerateRoute: _onGenerateRoute,
              ),
            ),
            const Positioned(left: 0, right: 0, bottom: 0, child: BottomFade()),
            Positioned(
              left: 16,
              right: 16,
              bottom: 22 + bottomInset,
              child: GlassTabBar(
                active: _detail?.tab ?? AppTab.values[_tab],
                onSelect: _openTab,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenObserver extends NavigatorObserver {
  _ScreenObserver(this.onChanged);

  final ValueChanged<AppScreen?> onChanged;

  void _notify(Route<dynamic>? route) {
    // Les pages d'onglets n'ont pas d'écran de détail : null.
    if (route != null) onChanged(AppScreen.fromRoute(route.settings.name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _notify(newRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify(previousRoute);
}
