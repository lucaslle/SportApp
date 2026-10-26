import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_shell.dart';
import 'app/demo_device_frame.dart';
import 'state/theme_providers.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final dark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    AppColors.use(dark ? AppPalette.dark : AppPalette.light);
    SystemChrome.setSystemUIOverlayStyle(dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
    return MaterialApp(
      title: 'Hargne',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => DemoDeviceFrame(child: child!),
      // Les couleurs sont lues à la construction des widgets : changer de thème
      // reconstruit tout l'écran (retour à l'accueil).
      home: AppShell(key: ValueKey(dark)),
    );
  }
}
