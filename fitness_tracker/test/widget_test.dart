import 'package:fitness_tracker/data/plan_storage.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/screens/body_screen.dart';
import 'package:fitness_tracker/screens/goals_screen.dart';
import 'package:fitness_tracker/screens/history_screen.dart';
import 'package:fitness_tracker/screens/stats_screen.dart';
import 'package:fitness_tracker/state/connections_providers.dart';
import 'package:fitness_tracker/models/sport.dart';
import 'package:fitness_tracker/state/record_providers.dart';
import 'package:fitness_tracker/state/session_providers.dart';
import 'package:fitness_tracker/state/weighing_providers.dart';
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
        demoDataProvider.overrideWithValue(true),
        athleteNameStorageProvider.overrideWithValue(MemoryPlanStorage()),
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

  testWidgets('hors démo, sorties, stats et records sont vides', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> pumpScreen(Widget screen) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [demoDataProvider.overrideWithValue(false)],
        child: MaterialApp(home: Scaffold(body: screen)),
      ));
      await tester.pumpAndSettle();
    }

    await pumpScreen(const HistoryScreen());
    expect(find.text('Aucune sortie pour l\'instant'), findsOneWidget);
    expect(find.text('Trail des Crêtes'), findsNothing);

    await pumpScreen(const StatsScreen());
    expect(find.text('Pas encore d\'activité'), findsOneWidget);

    await pumpScreen(const GoalsScreen());
    expect(find.text('Aucun record'), findsOneWidget);
    expect(find.text('18′42'), findsNothing);
  });

  testWidgets('les sorties faites et les pesées enregistrées s\'affichent', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final plan = MemoryPlanStorage();
    await plan.write('date;sport;titre;duree_min;distance_km;faite\r\n'
        '2026-10-20;CAP;Footing du lundi;50;10;oui\r\n'
        '2026-10-22;VÉLO;Sortie prévue;90;45;non\r\n');
    final weighings = MemoryPlanStorage();
    await weighings.write(WeighingsNotifier.encode([Weighing(date: DateTime(2026, 10, 20), kg: 68.4)]));

    Future<void> pumpScreen(Widget screen) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          demoDataProvider.overrideWithValue(false),
          todayProvider.overrideWithValue(DateTime(2026, 10, 26)),
          planStorageProvider.overrideWithValue(plan),
          weighingStorageProvider.overrideWithValue(weighings),
        ],
        child: MaterialApp(home: Scaffold(body: screen)),
      ));
      await tester.pumpAndSettle();
    }

    await pumpScreen(const HistoryScreen());
    expect(find.text('Footing du lundi'), findsOneWidget);
    expect(find.text('Sortie prévue'), findsNothing);
    expect(find.text('5′00'), findsOneWidget);

    await pumpScreen(const BodyScreen());
    expect(find.text('68,4'), findsOneWidget);
    expect(find.textContaining('Ajouter une pesée', findRichText: true), findsOneWidget);
  });

  testWidgets('Corps trace le poids et la masse grasse', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final weighings = MemoryPlanStorage();
    await weighings.write(WeighingsNotifier.encode([
      Weighing(date: DateTime(2026, 10, 1), kg: 70.2, fatPercent: 14.1),
      Weighing(date: DateTime(2026, 10, 10), kg: 69.6),
      Weighing(date: DateTime(2026, 10, 20), kg: 69.0, fatPercent: 13.4),
    ]));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        demoDataProvider.overrideWithValue(false),
        todayProvider.overrideWithValue(DateTime(2026, 10, 26)),
        weighingStorageProvider.overrideWithValue(weighings),
      ],
      child: const MaterialApp(home: Scaffold(body: BodyScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('POIDS'), findsOneWidget);
    expect(find.text('−1,2 kg'), findsOneWidget);
    expect(find.text('MASSE GRASSE'), findsOneWidget);
    expect(find.text('−0,7 %'), findsOneWidget);
  });

  testWidgets('un exercice ouvre sa courbe de progression', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final records = MemoryPlanStorage();
    await records.write(RecordsNotifier.encode([
      PersonalRecord(sport: Sport.muscu, label: 'Développé couché', value: '80 kg', date: DateTime(2026, 9, 1)),
      PersonalRecord(sport: Sport.muscu, label: 'Développé couché', value: '85 kg', date: DateTime(2026, 10, 15)),
    ]));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        demoDataProvider.overrideWithValue(false),
        recordStorageProvider.overrideWithValue(records),
      ],
      child: const MaterialApp(home: Scaffold(body: GoalsScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('85 kg'), findsOneWidget);
    expect(find.text('2 mesures'), findsOneWidget);
    await tester.tap(find.text('Développé couché'));
    await tester.pumpAndSettle();

    expect(find.text('PROGRESSION'), findsOneWidget);
    expect(find.text('+5 kg'), findsOneWidget);
  });

  testWidgets('Stats affiche les records et le volume réels', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final plan = MemoryPlanStorage();
    await plan.write('date;sport;titre;duree_min;distance_km;faite\r\n'
        '2026-10-20;CAP;Footing;50;10;oui\r\n'
        '2026-10-21;MUSCU;Haut du corps;45;;oui\r\n');
    final records = MemoryPlanStorage();
    await records.write(RecordsNotifier.encode([
      PersonalRecord(sport: Sport.muscu, label: 'Tractions', value: '15 reps', date: DateTime(2026, 10, 21)),
    ]));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        demoDataProvider.overrideWithValue(false),
        todayProvider.overrideWithValue(DateTime(2026, 10, 26)),
        planStorageProvider.overrideWithValue(plan),
        recordStorageProvider.overrideWithValue(records),
      ],
      child: const MaterialApp(home: Scaffold(body: StatsScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tractions'), findsOneWidget);
    expect(find.text('15 reps'), findsOneWidget);
    expect(find.text('Course à pied'), findsOneWidget);
    expect(find.text('Renforcement'), findsOneWidget);
  });
}
