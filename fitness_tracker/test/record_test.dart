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
}
