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

/// Cadre de l'application : navigateur interne + barre d'onglets flottante.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final _ScreenObserver _observer = _ScreenObserver(_onScreenChanged);
  AppScreen _current = AppScreen.home;

  /// Côté d'où arrive le prochain écran : 1 = droite, -1 = gauche.
  double _enterFrom = 1;

  void _onScreenChanged(AppScreen screen) {
    if (!mounted || screen == _current) return;
    setState(() => _current = screen);
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final screen = AppScreen.fromRoute(settings.name) ?? AppScreen.home;
    final page = switch (screen) {
      AppScreen.home => const HomeScreen(),
      AppScreen.plan => const PlanScreen(),
      AppScreen.calendar => const CalendarScreen(),
      AppScreen.session => SessionScreen(sessionId: settings.arguments as String?),
      AppScreen.body => const BodyScreen(),
      AppScreen.history => const HistoryScreen(),
      AppScreen.activity => ActivityScreen(sessionId: settings.arguments as String?),
      AppScreen.stats => const StatsScreen(),
      AppScreen.goals => const GoalsScreen(),
    };
    final from = _enterFrom;
    _enterFrom = 1;
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: screen.route, arguments: settings.arguments),
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => page,
      // Glissement léger avec fondu, du côté de l'onglet visé.
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: Offset(.08 * from, 0), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _openTab(AppTab tab) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    _enterFrom = tab.index < _current.tab.index ? -1 : 1;
    navigator.pushNamedAndRemoveUntil(AppScreen.rootOf(tab).route, (_) => false);
  }

  /// Glisser vers la gauche ou la droite passe à l'onglet voisin, depuis un écran principal seulement.
  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300 || _current != AppScreen.rootOf(_current.tab)) return;
    final next = _current.tab.index + (velocity < 0 ? 1 : -1);
    if (next < 0 || next >= AppTab.values.length) return;
    _openTab(AppTab.values[next]);
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
              child: GestureDetector(
                onHorizontalDragEnd: _onSwipe,
                child: Navigator(
                  key: _navigatorKey,
                  initialRoute: AppScreen.home.route,
                  observers: [_observer],
                  onGenerateRoute: _onGenerateRoute,
                ),
              ),
            ),
            const Positioned(left: 0, right: 0, bottom: 0, child: BottomFade()),
            Positioned(
              left: 16,
              right: 16,
              bottom: 22 + bottomInset,
              child: GlassTabBar(
                active: _current.tab,
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

  final ValueChanged<AppScreen> onChanged;

  void _notify(Route<dynamic>? route) {
    final screen = AppScreen.fromRoute(route?.settings.name);
    if (screen != null) onChanged(screen);
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
