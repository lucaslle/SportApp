import 'package:fitness_tracker/data/plan_storage.dart';
import 'package:fitness_tracker/models/sport.dart';
import 'package:fitness_tracker/models/workout_session.dart';
import 'package:fitness_tracker/state/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('une sortie Garmin complète la séance prévue le même jour au lieu de la doubler', () async {
    final container = ProviderContainer(overrides: [
      planStorageProvider.overrideWithValue(MemoryPlanStorage()),
      demoDataProvider.overrideWithValue(false),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(sessionsProvider.notifier);
    await container.read(sessionsProvider.future);
    await notifier.add(WorkoutSession(
        id: 'plan', date: DateTime(2026, 10, 27), sport: Sport.cap, title: 'Footing', durationMin: 45));

    final linked = await notifier.importGarmin([
      WorkoutSession(
          id: 'g1', date: DateTime(2026, 10, 27), sport: Sport.trail, title: 'Annecy Trail',
          durationMin: 52, distanceKm: 9.4, time: '18h05', tags: const ['GARMIN'], done: true, garminId: '123'),
      WorkoutSession(
          id: 'g2', date: DateTime(2026, 10, 27), sport: Sport.velo, title: 'Vélo',
          durationMin: 30, done: true, garminId: '456'),
    ]);

    final sessions = container.read(sessionsProvider).value!;
    expect(linked, 1);
    expect(sessions, hasLength(2));
    final run = sessions.firstWhere((s) => s.id == 'plan');
    expect(run.title, 'Footing');
    expect(run.done, isTrue);
    expect(run.garminId, '123');
    expect(run.distanceKm, 9.4);
    expect(run.durationMin, 52);
  });
}
