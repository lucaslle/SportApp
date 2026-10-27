import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plan_storage.dart';
import 'session_providers.dart';

final athleteNameStorageProvider =
    Provider<PlanStorage>((ref) => PlanStorage.forPlatform(fileName: 'nom_athlete.txt'));

/// Nom de l'athlète affiché sur l'accueil, modifiable et enregistré sur l'appareil.
final athleteNameProvider =
    AsyncNotifierProvider<AthleteNameNotifier, String>(AthleteNameNotifier.new);

class AthleteNameNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final stored = await ref.read(athleteNameStorageProvider).read();
    if (stored != null) return stored.trim();
    return ref.read(demoDataProvider) ? 'Thomas' : '';
  }

  Future<void> rename(String name) async {
    final trimmed = name.trim();
    state = AsyncData(trimmed);
    await ref.read(athleteNameStorageProvider).write(trimmed);
  }
}

/// Course objectif principale.
final goalRaceProvider = Provider<String>((ref) => 'Semi-marathon de Lyon');
