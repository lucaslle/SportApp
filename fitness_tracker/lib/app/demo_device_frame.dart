import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dans le cadre iPhone de la démo web (`?frame=iphone`, ajouté par la page sur
/// grand écran), dessine la barre d'état, la Dynamic Island et la barre
/// d'accueil, et réserve leur place via le padding de [MediaQuery].
/// Ailleurs (vrai téléphone, navigateur étroit), il est invisible.
class DemoDeviceFrame extends StatelessWidget {
  const DemoDeviceFrame({super.key, required this.child});

  static const double statusBarHeight = 54;
  static const double homeIndicatorHeight = 30;

  static bool get isFramed => kIsWeb && Uri.base.queryParameters['frame'] == 'iphone';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isFramed) return child;
    const insets = EdgeInsets.only(top: statusBarHeight, bottom: homeIndicatorHeight);
    return Stack(
      children: [
        MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: insets, viewPadding: insets),
          child: child,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: statusBarHeight,
          child: IgnorePointer(child: ExcludeSemantics(child: _StatusBar())),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.text,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Heure, île et indicateurs ; se rafraîchit pour garder l'heure juste.
class _StatusBar extends StatefulWidget {
  const _StatusBar();

  @override
  State<_StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<_StatusBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 20), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final clock = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Stack(
      children: [
        Positioned(
          top: 11,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 126,
              height: 37,
              decoration: BoxDecoration(
                color: Color(0xFF000000),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(44, 4, 30, 0),
            child: Row(
              children: [
                Text(clock, style: AppText.sans(size: 16, weight: FontWeight.w600, height: 1)),
                Spacer(),
                Icon(Icons.signal_cellular_alt, size: 17, color: AppColors.text),
                SizedBox(width: 5),
                Icon(Icons.wifi, size: 17, color: AppColors.text),
                SizedBox(width: 5),
                Icon(Icons.battery_full, size: 19, color: AppColors.text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
