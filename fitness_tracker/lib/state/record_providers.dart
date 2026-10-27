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

/// Historique des performances, trié par sport, épreuve puis date : chaque
/// mesure est gardée pour suivre la progression d'un exercice.
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

  Future<void> add(PersonalRecord record) async {
    final current = state.valueOrNull ?? const <PersonalRecord>[];
    await _commit([...current, record]);
  }

  Future<void> replace(PersonalRecord old, PersonalRecord record) async {
    final current = state.valueOrNull ?? const <PersonalRecord>[];
    await _commit([...current.where((other) => !identical(other, old)), record]);
  }

  Future<void> remove(PersonalRecord record) async {
    final current = state.valueOrNull ?? const <PersonalRecord>[];
    await _commit(current.where((other) => !identical(other, record)).toList());
  }

  Future<void> _commit(List<PersonalRecord> records) async {
    final sorted = [...records]
      ..sort((a, b) {
        final bySport = a.sport.index.compareTo(b.sport.index);
        if (bySport != 0) return bySport;
        final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
        return byLabel != 0 ? byLabel : a.date.compareTo(b.date);
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

/// Toutes les mesures d'un même exercice (même sport, même épreuve), par date.
class RecordSeries {
  RecordSeries(this.entries);

  final List<PersonalRecord> entries;

  Sport get sport => entries.first.sport;
  String get label => entries.first.label;

  /// Mesures dont la performance se lit comme un nombre, pour le graphique.
  List<(DateTime, double)> get points => [
        for (final entry in entries)
          if (parseRecordValue(entry.value) case (final value, _)) (entry.date, value),
      ];

  /// La meilleure mesure : le temps le plus court, sinon la valeur la plus haute
  /// (charge, distance, puissance). La plus récente si rien n'est chiffré.
  PersonalRecord get best {
    PersonalRecord? best;
    double? bestValue;
    for (final entry in entries) {
      final parsed = parseRecordValue(entry.value);
      if (parsed == null) continue;
      final (value, isTime) = parsed;
      if (bestValue == null || (isTime ? value < bestValue : value > bestValue)) {
        best = entry;
        bestValue = value;
      }
    }
    return best ?? entries.last;
  }

  static List<RecordSeries> group(List<PersonalRecord> records) {
    final series = <String, List<PersonalRecord>>{};
    for (final record in records) {
      series.putIfAbsent('${record.sport.code}|${record.label.trim().toLowerCase()}', () => []).add(record);
    }
    return [for (final entries in series.values) RecordSeries(entries..sort((a, b) => a.date.compareTo(b.date)))];
  }
}

/// Valeur chiffrée d'une performance : des secondes pour un temps ("39′10",
/// "1h31′05", "39:10"), sinon le premier nombre ("100 kg", "272 W", "1 480 m").
(double, bool)? parseRecordValue(String text) {
  final time = RegExp(r"^\s*(?:(\d+)\s*h\s*)?(\d{1,2})\s*[′':]\s*(\d{1,2})").firstMatch(text) ??
      RegExp(r"^\s*(\d+)\s*h\s*(\d{1,2})()").firstMatch(text);
  if (time != null) {
    final hours = int.tryParse(time.group(1) ?? '') ?? 0;
    final minutes = int.parse(time.group(2)!);
    final seconds = int.tryParse(time.group(3) ?? '') ?? 0;
    return ((hours * 3600 + minutes * 60 + seconds).toDouble(), true);
  }
  final number = RegExp(r'\d[\d\s]*(?:[.,]\d+)?').firstMatch(text);
  if (number == null) return null;
  final value = double.tryParse(number.group(0)!.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.'));
  return value == null ? null : (value, false);
}

/// Écrit une valeur de [parseRecordValue] : "39′10", "1h31′05" ou "102,5".
String formatRecordValue(double value, {required bool isTime}) {
  if (!isTime) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1).replaceAll('.', ',');
  }
  final seconds = value.round().abs();
  final hours = seconds ~/ 3600;
  final rest = '${(seconds % 3600) ~/ 60}′${(seconds % 60).toString().padLeft(2, '0')}';
  return hours > 0 ? '${hours}h${rest.padLeft(5, '0')}' : rest;
}
