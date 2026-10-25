import 'package:fitness_tracker/data/csv_parser.dart';
import 'package:fitness_tracker/data/session_csv_codec.dart';
import 'package:fitness_tracker/models/sport.dart';
import 'package:fitness_tracker/models/workout_session.dart';
import 'package:fitness_tracker/utils/fr_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvParser', () {
    test('détecte le séparateur et gère les guillemets', () {
      const text = 'a;b;c\r\n1;"x;y";"il a dit ""ok"""\r\n';
      final rows = CsvParser.parse(text);
      expect(rows, [
        ['a', 'b', 'c'],
        ['1', 'x;y', 'il a dit "ok"'],
      ]);
    });

    test('accepte la virgule, le BOM et les retours à la ligne dans un champ', () {
      const text = '﻿date,titre\n2026-09-14,"ligne 1\nligne 2"\n\n';
      final rows = CsvParser.parse(text);
      expect(rows.length, 2);
      expect(rows[1][1], 'ligne 1\nligne 2');
    });

    test('encode avec guillemets quand nécessaire', () {
      final text = CsvParser.encode([
        ['a', 'b;c', 'd"e'],
      ]);
      expect(text, '﻿a;"b;c";"d""e"\r\n');
    });
  });

  group('FrDate', () {
    test('semaine ISO et jours civils, y compris à cheval sur l\'heure d\'été', () {
      expect(FrDate.isoWeek(DateTime(2026, 9, 14)), 38);
      expect(FrDate.isoWeek(DateTime(2026, 1, 1)), 1);
      expect(FrDate.isoWeek(DateTime(2027, 1, 3)), 53);
      expect(FrDate.daysBetween(DateTime(2026, 1, 1), DateTime(2026, 9, 17)), 259);
      expect(FrDate.mondayOf(DateTime(2026, 9, 20)), DateTime(2026, 9, 14));
      expect(FrDate.weekRange(DateTime(2026, 9, 28)), '28 sept. → 4 oct.');
    });
  });

  group('SessionCsvCodec', () {
    final session = WorkoutSession(
      id: 'x',
      date: DateTime(2026, 9, 14),
      sport: Sport.cap,
      title: 'Fractionné 8 × 400 m',
      subtitle: 'Piste · récup 90″ · objectif 3′20/km',
      durationMin: 55,
      distanceKm: 11,
      targetPace: '3′20 /km',
      targetHr: 'Z4 · 172',
      rpe: 8,
      time: '18h30',
      location: 'Stade Léo Lagrange',
      tags: const ['PISTE', 'VMA'],
      blocks: const [
        SessionBlock(title: 'Échauffement', detail: 'Footing souple', durationMin: 20),
        SessionBlock(
          title: '8 × 400 m',
          detail: '@ 3′20/km · récup 90″',
          durationMin: 25,
          intensity: BlockIntensity.high,
        ),
      ],
      done: true,
      notes: 'Bonnes sensations ; vent fort',
    );

    test('export puis import restitue la séance', () {
      final csv = SessionCsvCodec.encode([session]);
      final decoded = SessionCsvCodec.decode(csv);

      expect(decoded.length, 1);
      final back = decoded.single;
      expect(back.date, session.date);
      expect(back.sport, Sport.cap);
      expect(back.title, session.title);
      expect(back.subtitle, session.subtitle);
      expect(back.durationMin, 55);
      expect(back.distanceKm, 11);
      expect(back.targetPace, session.targetPace);
      expect(back.targetHr, session.targetHr);
      expect(back.rpe, 8);
      expect(back.time, '18h30');
      expect(back.location, session.location);
      expect(back.tags, ['PISTE', 'VMA']);
      expect(back.blocks, session.blocks);
      expect(back.done, isTrue);
      expect(back.notes, session.notes);
    });

    test('la première ligne est l\'en-tête attendu', () {
      final csv = SessionCsvCodec.encode(const []);
      final firstLine = csv.replaceFirst('﻿', '').split('\r\n').first;
      expect(
        firstLine,
        'date;sport;titre;sous_titre;duree_min;distance_km;allure_cible;fc_cible;rpe;heure;lieu;tags;structure;faite;notes',
      );
    });

    test('importe un fichier minimal écrit à la main, colonnes dans le désordre', () {
      const csv = 'Sport,Titre,Date,Durée\n'
          'velo,Endurance,14/09/2026,1h30\n'
          'REST,Repos,15/09/2026,\n';
      final decoded = SessionCsvCodec.decode(csv);
      expect(decoded.length, 2);
      expect(decoded[0].sport, Sport.velo);
      expect(decoded[0].date, DateTime(2026, 9, 14));
      expect(decoded[0].durationMin, 90);
      expect(decoded[1].sport, Sport.repos);
    });

    test('lit les durées sous plusieurs écritures', () {
      expect(SessionCsvCodec.parseDurationMinutes('55'), 55);
      expect(SessionCsvCodec.parseDurationMinutes('55 min'), 55);
      expect(SessionCsvCodec.parseDurationMinutes('55′'), 55);
      expect(SessionCsvCodec.parseDurationMinutes('1h30'), 90);
      expect(SessionCsvCodec.parseDurationMinutes('2h'), 120);
      expect(SessionCsvCodec.parseDurationMinutes('01:05'), 65);
      expect(SessionCsvCodec.parseDurationMinutes('longue'), isNull);
    });

    test('accepte la virgule décimale et oui/non', () {
      const csv = 'date;sport;titre;distance_km;faite\n2026-09-14;CAP;Footing;10,5;Oui\n';
      final decoded = SessionCsvCodec.decode(csv).single;
      expect(decoded.distanceKm, 10.5);
      expect(decoded.done, isTrue);
    });

    test('signale la ligne fautive', () {
      const csv = 'date;sport;titre\n2026-09-14;CAP;OK\n2026-13-40;CAP;KO\n';
      expect(
        () => SessionCsvCodec.decode(csv),
        throwsA(
          isA<CsvImportException>()
              .having((error) => error.line, 'line', 3)
              .having((error) => error.message, 'message', contains('Date invalide')),
        ),
      );
    });

    test('refuse un en-tête sans colonne obligatoire', () {
      const csv = 'date;titre\n2026-09-14;Footing\n';
      expect(
        () => SessionCsvCodec.decode(csv),
        throwsA(isA<CsvImportException>().having((error) => error.line, 'line', 1)),
      );
    });

    test('refuse un sport inconnu', () {
      const csv = 'date;sport;titre\n2026-09-14;ESCALADE;Bloc\n';
      expect(
        () => SessionCsvCodec.decode(csv),
        throwsA(isA<CsvImportException>().having((error) => error.message, 'message', contains('Sport inconnu'))),
      );
    });
  });
}
