import 'package:fitness_tracker/models/workout_session.dart';
import 'package:fitness_tracker/screens/rest_timer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('séries et repos lus dans l\'exercice', () {
    expect(setsOf(const SessionBlock(title: 'Squats', detail: '4 × 8 · charge modérée')), 4);
    expect(setsOf(const SessionBlock(title: '8x400 m')), 8);
    expect(setsOf(const SessionBlock(title: 'Gainage')), 3);
    expect(restSecondsOf(const SessionBlock(title: '8 × 400 m', detail: '@ 3′20/km · récup 90″ trot')), 90);
    expect(restSecondsOf(const SessionBlock(title: 'Squats', detail: 'repos 2′')), 120);
    expect(restSecondsOf(const SessionBlock(title: 'Squats', detail: "récup 1'30")), 90);
    expect(restSecondsOf(const SessionBlock(title: 'Squats')), 90);
  });

  testWidgets('une série terminée lance le repos, puis la série suivante', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showRestTimer(context, const SessionBlock(title: 'Tractions', detail: '2 × 8 · repos 30″')),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Série 1 sur 2'), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);

    await tester.tap(find.text('Série 1 terminée · repos'));
    await tester.pump();
    expect(find.text('avant la série 2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.text('Série 2 sur 2'), findsOneWidget);

    await tester.tap(find.text('Dernière série terminée'));
    await tester.pumpAndSettle();
    expect(find.text('Exercice terminé'), findsOneWidget);
  });
}
