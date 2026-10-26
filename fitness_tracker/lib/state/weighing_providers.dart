import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/csv_parser.dart';
import '../data/plan_storage.dart';
import '../utils/fr_date.dart';
import 'session_providers.dart';

/// Une pesée : poids et, si la balance la donne, masse grasse.
class Weighing {
  Weighing({required DateTime date, required this.kg, this.fatPercent})
      : date = DateTime(date.year, date.month, date.day);

  final DateTime date;
  final double kg;
  final double? fatPercent;
}

final weighingStorageProvider =
    Provider<PlanStorage>((ref) => PlanStorage.forPlatform(fileName: 'pesees.csv'));

/// Pesées triées de la plus ancienne à la plus récente, une seule par jour.
final weighingsProvider =
    AsyncNotifierProvider<WeighingsNotifier, List<Weighing>>(WeighingsNotifier.new);

class WeighingsNotifier extends AsyncNotifier<List<Weighing>> {
  static const List<String> _header = ['date', 'poids_kg', 'masse_grasse_pct'];

  @override
  Future<List<Weighing>> build() async {
    final stored = await ref.read(weighingStorageProvider).read();
    if (stored == null || stored.trim().isEmpty) {
      return ref.read(demoDataProvider) ? _demo(ref.read(todayProvider)) : const [];
    }
    return decode(stored);
  }

  /// Ajoute une pesée ; celle du même jour est remplacée.
  Future<void> add(Weighing weighing) async {
    final current = state.valueOrNull ?? const <Weighing>[];
    await _commit([
      ...current.where((other) => !FrDate.sameDay(other.date, weighing.date)),
      weighing,
    ]);
  }

  Future<void> remove(Weighing weighing) async {
    final current = state.valueOrNull ?? const <Weighing>[];
    await _commit(current.where((other) => !FrDate.sameDay(other.date, weighing.date)).toList());
  }

  Future<void> _commit(List<Weighing> weighings) async {
    final sorted = [...weighings]..sort((a, b) => a.date.compareTo(b.date));
    state = AsyncData(sorted);
    await ref.read(weighingStorageProvider).write(encode(sorted));
  }

  static String encode(List<Weighing> weighings) => CsvParser.encode([
        _header,
        for (final weighing in weighings)
          [FrDate.iso(weighing.date), '${weighing.kg}', weighing.fatPercent?.toString() ?? ''],
      ]);

  /// Les lignes illisibles sont ignorées plutôt que de perdre tout l'historique.
  static List<Weighing> decode(String csv) {
    final weighings = <Weighing>[];
    for (final row in CsvParser.parse(csv).skip(1)) {
      final date = row.isNotEmpty ? FrDate.tryParse(row[0]) : null;
      final kg = row.length > 1 ? double.tryParse(row[1]) : null;
      if (date == null || kg == null) continue;
      weighings.add(Weighing(
        date: date,
        kg: kg,
        fatPercent: row.length > 2 ? double.tryParse(row[2]) : null,
      ));
    }
    return weighings..sort((a, b) => a.date.compareTo(b.date));
  }

  static List<Weighing> _demo(DateTime today) {
    const kgs = [70.2, 70.0, 69.8, 69.9, 69.4, 69.5, 69.1, 68.9, 69.0, 68.7, 68.5, 68.4];
    return [
      for (var i = 0; i < kgs.length; i++)
        Weighing(
          date: today.subtract(Duration(days: 7 * (kgs.length - 1 - i))),
          kg: kgs[i],
          fatPercent: double.parse((13.2 - i * .07).toStringAsFixed(1)),
        ),
    ];
  }
}
