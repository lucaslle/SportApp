import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plan_storage.dart';
import '../data/sample_plan.dart';
import '../data/session_csv_codec.dart';
import '../models/sport.dart';
import '../models/workout_session.dart';
import '../utils/fr_date.dart';

/// Date du jour (surchargeable dans les tests).
final todayProvider = Provider<DateTime>((ref) => FrDate.dateOnly(DateTime.now()));

final planStorageProvider = Provider<PlanStorage>((ref) => PlanStorage.forPlatform());

/// Lundi de la semaine affichée dans l'écran Plan.
final weekMondayProvider = StateProvider<DateTime>(
  (ref) => FrDate.mondayOf(ref.watch(todayProvider)),
);

/// Mois affiché dans le calendrier (premier jour du mois).
final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final today = ref.watch(todayProvider);
  return DateTime(today.year, today.month);
});

/// Jour sélectionné dans le calendrier.
final calendarSelectedDayProvider = StateProvider<DateTime>(
  (ref) => ref.watch(todayProvider),
);

/// Stratégie d'import CSV.
enum ImportMode { merge, replace }

/// Résultat d'un import.
class ImportResult {
  const ImportResult({required this.imported, required this.replaced});

  final int imported;
  final int replaced;
}

final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, List<WorkoutSession>>(SessionsNotifier.new);

class SessionsNotifier extends AsyncNotifier<List<WorkoutSession>> {
  @override
  Future<List<WorkoutSession>> build() async {
    final storage = ref.read(planStorageProvider);
    final stored = await storage.read();
    if (stored == null || stored.trim().isEmpty) {
      final sample = SamplePlan.build(ref.read(todayProvider));
      await storage.write(SessionCsvCodec.encode(sample));
      return _sorted(sample);
    }
    try {
      return _sorted(SessionCsvCodec.decode(stored));
    } on CsvImportException {
      return _sorted(SamplePlan.build(ref.read(todayProvider)));
    }
  }

  List<WorkoutSession> get _current => state.valueOrNull ?? const [];

  Future<void> _commit(List<WorkoutSession> sessions) async {
    final sorted = _sorted(sessions);
    state = AsyncData(sorted);
    await ref.read(planStorageProvider).write(SessionCsvCodec.encode(sorted));
  }

  static List<WorkoutSession> _sorted(List<WorkoutSession> sessions) {
    final copy = [...sessions];
    copy.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.time.compareTo(b.time);
    });
    return copy;
  }

  Future<void> add(WorkoutSession session) => _commit([..._current, session]);

  Future<void> edit(WorkoutSession session) => _commit([
        for (final existing in _current)
          if (existing.id == session.id) session else existing,
      ]);

  Future<void> remove(String id) =>
      _commit(_current.where((session) => session.id != id).toList());

  Future<void> toggleDone(String id) => _commit([
        for (final existing in _current)
          if (existing.id == id) existing.copyWith(done: !existing.done) else existing,
      ]);

  /// Duplique la semaine commençant le [monday] sur la semaine suivante.
  Future<int> duplicateWeek(DateTime monday) async {
    final source = forWeek(_current, monday);
    final copies = source
        .map(
          (session) => session.copyWith(
            id: WorkoutSession.newId(),
            date: session.date.add(const Duration(days: 7)),
            done: false,
          ),
        )
        .toList();
    await _commit([..._current, ...copies]);
    return copies.length;
  }

  /// Importe [incoming]. En mode [ImportMode.merge], une séance existante le
  /// même jour avec le même titre est remplacée ; en mode
  /// [ImportMode.replace], tout le plan est remplacé.
  Future<ImportResult> importSessions(
    List<WorkoutSession> incoming, {
    required ImportMode mode,
  }) async {
    if (mode == ImportMode.replace) {
      final replaced = _current.length;
      await _commit(incoming);
      return ImportResult(imported: incoming.length, replaced: replaced);
    }
    String keyOf(WorkoutSession session) =>
        '${FrDate.iso(session.date)}|${session.title.trim().toLowerCase()}';
    final incomingKeys = incoming.map(keyOf).toSet();
    final kept = _current.where((session) => !incomingKeys.contains(keyOf(session))).toList();
    final replaced = _current.length - kept.length;
    await _commit([...kept, ...incoming]);
    return ImportResult(imported: incoming.length, replaced: replaced);
  }

  /// CSV de tout le plan, ou de la seule semaine de [weekMonday].
  String exportCsv({DateTime? weekMonday}) {
    final sessions = weekMonday == null ? _current : forWeek(_current, weekMonday);
    return SessionCsvCodec.encode(sessions);
  }

  static List<WorkoutSession> forWeek(List<WorkoutSession> sessions, DateTime monday) {
    final end = monday.add(const Duration(days: 7));
    return sessions
        .where((session) => !session.date.isBefore(monday) && session.date.isBefore(end))
        .toList();
  }

  static List<WorkoutSession> forDay(List<WorkoutSession> sessions, DateTime day) =>
      sessions.where((session) => FrDate.sameDay(session.date, day)).toList();
}

/// Indicateurs agrégés d'une semaine.
class WeekSummary {
  const WeekSummary({
    required this.sessionCount,
    required this.totalMinutes,
    required this.doneMinutes,
    required this.runningKm,
  });

  factory WeekSummary.of(List<WorkoutSession> weekSessions) {
    var total = 0;
    var done = 0;
    var km = 0.0;
    var count = 0;
    for (final session in weekSessions) {
      if (session.isRest) continue;
      count++;
      total += session.durationMin;
      if (session.done) done += session.durationMin;
      if (session.sport == Sport.cap || session.sport == Sport.trail) {
        km += session.distanceKm ?? 0;
      }
    }
    return WeekSummary(
      sessionCount: count,
      totalMinutes: total,
      doneMinutes: done,
      runningKm: km,
    );
  }

  final int sessionCount;
  final int totalMinutes;
  final int doneMinutes;
  final double runningKm;
}
