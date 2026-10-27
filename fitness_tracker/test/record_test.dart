import 'package:fitness_tracker/models/sport.dart';
import 'package:fitness_tracker/state/record_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les records survivent à un aller-retour CSV, virgules comprises', () {
    final csv = RecordsNotifier.encode([
      PersonalRecord(sport: Sport.cap, label: '10 km', value: '39′10', date: DateTime(2026, 6, 14)),
      PersonalRecord(sport: Sport.velo, label: 'FTP, estimée', value: '272 W', date: DateTime(2026, 9, 3)),
    ]);
    final decoded = RecordsNotifier.decode(csv);

    expect(decoded, hasLength(2));
    expect(decoded.first.sport, Sport.cap);
    expect(decoded.first.value, '39′10');
    expect(decoded.last.label, 'FTP, estimée');
    expect(decoded.last.date, DateTime(2026, 9, 3));
  });

  test('une ligne incomplète est ignorée', () {
    final decoded = RecordsNotifier.decode('sport;epreuve;performance;date\r\n'
        'CAP;5 km;;2026-05-10\r\n'
        'NAT;1 000 m;17′24;2026-07-18\r\n');

    expect(decoded.single.label, '1 000 m');
  });

  test('les performances se lisent en nombres ou en temps', () {
    expect(parseRecordValue('100 kg'), (100.0, false));
    expect(parseRecordValue('15 reps'), (15.0, false));
    expect(parseRecordValue('102,5 kg'), (102.5, false));
    expect(parseRecordValue('1 480 m'), (1480.0, false));
    expect(parseRecordValue('39′10'), (2350.0, true));
    expect(parseRecordValue('39:10'), (2350.0, true));
    expect(parseRecordValue('1h31′05'), (5465.0, true));
    expect(parseRecordValue('1h31'), (5460.0, true));
    expect(parseRecordValue('à revoir'), isNull);
    expect(formatRecordValue(5465, isTime: true), '1h31′05');
    expect(formatRecordValue(102.5, isTime: false), '102,5');
  });

  test('un exercice garde toutes ses mesures et son meilleur résultat', () {
    final series = RecordSeries.group([
      PersonalRecord(sport: Sport.muscu, label: 'Squat', value: '100 kg', date: DateTime(2026, 9, 1)),
      PersonalRecord(sport: Sport.muscu, label: 'squat', value: '110 kg', date: DateTime(2026, 10, 1)),
      PersonalRecord(sport: Sport.muscu, label: 'Squat', value: '105 kg', date: DateTime(2026, 10, 20)),
      PersonalRecord(sport: Sport.cap, label: '10 km', value: '41′00', date: DateTime(2026, 5, 1)),
      PersonalRecord(sport: Sport.cap, label: '10 km', value: '39′10', date: DateTime(2026, 6, 1)),
    ]);

    final squat = series.firstWhere((s) => s.sport == Sport.muscu);
    expect(squat.entries, hasLength(3));
    expect(squat.best.value, '110 kg');
    expect(squat.points.map((p) => p.$2), [100, 110, 105]);
    expect(series.firstWhere((s) => s.sport == Sport.cap).best.value, '39′10');
  });
}
