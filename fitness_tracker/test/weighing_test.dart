import 'package:fitness_tracker/state/weighing_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les pesées survivent à un aller-retour CSV', () {
    final csv = WeighingsNotifier.encode([
      Weighing(date: DateTime(2026, 10, 1), kg: 70.4, fatPercent: 13.1),
      Weighing(date: DateTime(2026, 10, 8), kg: 69.8),
    ]);
    final decoded = WeighingsNotifier.decode(csv);

    expect(decoded, hasLength(2));
    expect(decoded.first.kg, 70.4);
    expect(decoded.first.fatPercent, 13.1);
    expect(decoded.last.date, DateTime(2026, 10, 8));
    expect(decoded.last.fatPercent, isNull);
  });

  test('une ligne illisible est ignorée sans perdre les autres', () {
    final decoded = WeighingsNotifier.decode('date;poids_kg;masse_grasse_pct\r\n'
        'pas une date;70;\r\n'
        '2026-10-08;69,8;\r\n'
        '2026-10-01;70.4;12\r\n');

    expect(decoded, hasLength(1));
    expect(decoded.single.date, DateTime(2026, 10, 1));
  });
}
