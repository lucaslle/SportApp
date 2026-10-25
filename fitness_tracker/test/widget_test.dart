import 'package:fitness_tracker/data/plan_storage.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/state/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildApp(MemoryPlanStorage storage) {
    return ProviderScope(
      overrides: [
        planStorageProvider.overrideWithValue(storage),
        todayProvider.overrideWithValue(DateTime(2026, 9, 14)),
      ],
      child: const MyApp(),
    );
  }

  testWidgets('affiche l\'accueil avec la séance du jour', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(MemoryPlanStorage()));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour Thomas'), findsOneWidget);
    expect(find.text('SÉANCE DU JOUR'), findsOneWidget);
    expect(find.text('Fractionné 8 × 400 m'), findsOneWidget);
  });

  testWidgets('le plan liste la semaine et ouvre le détail de séance', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(MemoryPlanStorage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLAN'));
    await tester.pumpAndSettle();

    expect(find.text('PLAN — SEMAINE 38'), findsOneWidget);
    expect(find.text('14 → 20 sept.'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);

    await tester.tap(find.text('Fractionné 8 × 400 m'));
    await tester.pumpAndSettle();

    expect(find.text('STRUCTURE'), findsOneWidget);
    // Défile jusqu'en bas : la marge basse de la liste dégage le bouton
    // de la barre d'onglets flottante.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Marquer comme faite'), findsOneWidget);

    await tester.tap(find.text('Marquer comme faite'));
    await tester.pumpAndSettle();

    expect(find.text('Marquer à faire'), findsOneWidget);
  });

  testWidgets('la feuille CSV s\'ouvre depuis le plan', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = MemoryPlanStorage();
    await tester.pumpWidget(buildApp(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLAN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();

    expect(find.text('Programmation des séances'), findsOneWidget);
    expect(find.text('Choisir un fichier CSV'), findsOneWidget);

    final stored = await storage.read();
    expect(stored, isNotNull);
    expect(stored, contains('date;sport;titre'));
  });
}
