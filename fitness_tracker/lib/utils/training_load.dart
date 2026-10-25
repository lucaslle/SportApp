import '../models/workout_session.dart';

/// Charge d'entraînement approximative d'une séance (durée × effort perçu),
/// en unités arbitraires cohérentes avec la maquette.
abstract final class TrainingLoad {
  static int of(WorkoutSession session) {
    if (session.isRest || session.durationMin == 0) return 0;
    final rpe = session.rpe ?? 5;
    return (session.durationMin * rpe / 5.6).round();
  }

  static int sum(Iterable<WorkoutSession> sessions) =>
      sessions.fold(0, (total, session) => total + of(session));
}
