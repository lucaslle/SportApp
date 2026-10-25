import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Nom de l'athlète affiché sur l'accueil.
final athleteNameProvider = Provider<String>((ref) => 'Thomas');

/// Course objectif principale.
final goalRaceProvider = Provider<String>((ref) => 'Semi-marathon de Lyon');
