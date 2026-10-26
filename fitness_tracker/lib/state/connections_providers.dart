import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plan_storage.dart';
import 'session_providers.dart';

/// État des connexions externes (maquette : pas de vraie synchro).
final stravaConnectedProvider = StateProvider<bool>((ref) => true);

final garminConnectedProvider = StateProvider<bool>((ref) => true);

/// Identifiants des séances déjà envoyées sur la montre.
final sentToWatchProvider = StateProvider<Set<String>>((ref) => <String>{});

/// Options d'envoi vers la montre.
class WatchOptions {
  const WatchOptions({this.auto = true, this.targets = true, this.sync = true});

  final bool auto;
  final bool targets;
  final bool sync;

  WatchOptions copyWith({bool? auto, bool? targets, bool? sync}) => WatchOptions(
        auto: auto ?? this.auto,
        targets: targets ?? this.targets,
        sync: sync ?? this.sync,
      );
}

final watchOptionsProvider = StateProvider<WatchOptions>((ref) => const WatchOptions());

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
    return ref.read(seedSamplePlanProvider) ? 'Thomas' : '';
  }

  Future<void> rename(String name) async {
    final trimmed = name.trim();
    state = AsyncData(trimmed);
    await ref.read(athleteNameStorageProvider).write(trimmed);
  }
}

/// Course objectif principale.
final goalRaceProvider = Provider<String>((ref) => 'Semi-marathon de Lyon');
