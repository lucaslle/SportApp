import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/csv_parser.dart';
import '../data/plan_storage.dart';
import '../models/sport.dart';
import '../utils/fr_date.dart';
import 'session_providers.dart';

/// Un record personnel saisi à la main, ex. CAP · 10 km · 39′10.
class PersonalRecord {
  PersonalRecord({required this.sport, required this.label, required this.value, required DateTime date})
      : date = DateTime(date.year, date.month, date.day);

  final Sport sport;

  /// Épreuve ou mesure : "10 km", "FTP", "D+ sur une sortie"…
  final String label;

  /// Performance en texte libre : "39′10", "272 W", "1 480 m"…
  final String value;
  final DateTime date;
}

final recordStorageProvider = Provider<PlanStorage>((ref) => PlanStorage.forPlatform(fileName: 'records.csv'));

/// Records triés par sport puis par épreuve.
final recordsProvider = AsyncNotifierProvider<RecordsNotifier, List<PersonalRecord>>(RecordsNotifier.new);

class RecordsNotifier extends AsyncNotifier<List<PersonalRecord>> {
  static const List<String> _header = ['sport', 'epreuve', 'performance', 'date'];

  @override
  Future<List<PersonalRecord>> build() async {
    final stored = await ref.read(recordStorageProvider).read();
    if (stored == null || stored.trim().isEmpty) {
      return ref.read(demoDataProvider) ? _demo() : const [];
    }
    return decode(stored);
  }

  /// Ajoute un record ; celui du même sport et de la même épreuve est remplacé.
  Future<void> add(PersonalRecord record) async {
    final current = state.valueOrNull ?? const <PersonalRecord>[];
    await _commit([...current.where((other) => !_same(other, record)), record]);
  }

  Future<void> remove(PersonalRecord record) async {
    final current = state.valueOrNull ?? const <PersonalRecord>[];
    await _commit(current.where((other) => !identical(other, record)).toList());
  }

  static bool _same(PersonalRecord a, PersonalRecord b) =>
      a.sport == b.sport && a.label.trim().toLowerCase() == b.label.trim().toLowerCase();

  Future<void> _commit(List<PersonalRecord> records) async {
    final sorted = [...records]
      ..sort((a, b) {
        final bySport = a.sport.index.compareTo(b.sport.index);
        return bySport != 0 ? bySport : a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });
    state = AsyncData(sorted);
    await ref.read(recordStorageProvider).write(encode(sorted));
  }

  static String encode(List<PersonalRecord> records) => CsvParser.encode([
        _header,
        for (final record in records) [record.sport.code, record.label, record.value, FrDate.iso(record.date)],
      ]);

  /// Les lignes illisibles sont ignorées plutôt que de perdre tous les records.
  static List<PersonalRecord> decode(String csv) {
    final records = <PersonalRecord>[];
    for (final row in CsvParser.parse(csv).skip(1)) {
      if (row.length < 4) continue;
      final sport = Sport.tryParse(row[0]);
      final date = FrDate.tryParse(row[3]);
      if (sport == null || date == null || row[1].trim().isEmpty || row[2].trim().isEmpty) continue;
      records.add(PersonalRecord(sport: sport, label: row[1].trim(), value: row[2].trim(), date: date));
    }
    return records;
  }

  static List<PersonalRecord> _demo() => [
        PersonalRecord(sport: Sport.cap, label: '5 km', value: '18′42', date: DateTime(2026, 5, 10)),
        PersonalRecord(sport: Sport.cap, label: '10 km', value: '39′10', date: DateTime(2026, 6, 14)),
        PersonalRecord(sport: Sport.cap, label: 'Semi-marathon', value: '1h31′05', date: DateTime(2026, 3, 22)),
        PersonalRecord(sport: Sport.trail, label: 'D+ sur une sortie', value: '1 480 m', date: DateTime(2026, 8, 9)),
        PersonalRecord(sport: Sport.velo, label: 'FTP estimée', value: '272 W', date: DateTime(2026, 9, 3)),
        PersonalRecord(sport: Sport.nat, label: '1 000 m', value: '17′24', date: DateTime(2026, 7, 18)),
      ];
}
