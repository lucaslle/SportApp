import 'sport.dart';

/// Intensité d'un bloc : pilote la couleur de la barre dans le détail de séance.
enum BlockIntensity {
  low('L'),
  medium('M'),
  high('H');

  const BlockIntensity(this.code);

  final String code;

  static BlockIntensity fromCode(String code) {
    return BlockIntensity.values.firstWhere(
      (intensity) => intensity.code == code.trim().toUpperCase(),
      orElse: () => BlockIntensity.medium,
    );
  }
}

/// Un bloc de la structure d'une séance (échauffement, corps, retour au calme…).
class SessionBlock {
  const SessionBlock({
    required this.title,
    this.detail = '',
    this.durationMin = 0,
    this.intensity = BlockIntensity.medium,
  });

  final String title;
  final String detail;
  final int durationMin;
  final BlockIntensity intensity;

  @override
  bool operator ==(Object other) =>
      other is SessionBlock &&
      other.title == title &&
      other.detail == detail &&
      other.durationMin == durationMin &&
      other.intensity == intensity;

  @override
  int get hashCode => Object.hash(title, detail, durationMin, intensity);
}

/// Une séance programmée dans le plan.
class WorkoutSession {
  WorkoutSession({
    required this.id,
    required DateTime date,
    required this.sport,
    required this.title,
    this.subtitle = '',
    this.durationMin = 0,
    this.distanceKm,
    this.targetPace = '',
    this.targetHr = '',
    this.rpe,
    this.time = '',
    this.location = '',
    this.tags = const [],
    this.blocks = const [],
    this.done = false,
    this.notes = '',
  }) : date = DateTime(date.year, date.month, date.day);

  final String id;

  /// Jour de la séance, sans composante horaire.
  final DateTime date;
  final Sport sport;
  final String title;
  final String subtitle;
  final int durationMin;
  final double? distanceKm;
  final String targetPace;
  final String targetHr;
  final int? rpe;

  /// Heure libre, ex. "18h30".
  final String time;
  final String location;
  final List<String> tags;
  final List<SessionBlock> blocks;
  final bool done;
  final String notes;

  bool get isRest => sport.isRest;

  /// Libellé court façon "55′" ou "1h30".
  String get durationLabel => formatDuration(durationMin);

  static String formatDuration(int minutes) {
    if (minutes <= 0) return '—';
    if (minutes < 60) return '$minutes′';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) return '${hours}h';
    return '${hours}h${rest.toString().padLeft(2, '0')}';
  }

  WorkoutSession copyWith({
    String? id,
    DateTime? date,
    Sport? sport,
    String? title,
    String? subtitle,
    int? durationMin,
    double? Function()? distanceKm,
    String? targetPace,
    String? targetHr,
    int? Function()? rpe,
    String? time,
    String? location,
    List<String>? tags,
    List<SessionBlock>? blocks,
    bool? done,
    String? notes,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      date: date ?? this.date,
      sport: sport ?? this.sport,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      durationMin: durationMin ?? this.durationMin,
      distanceKm: distanceKm == null ? this.distanceKm : distanceKm(),
      targetPace: targetPace ?? this.targetPace,
      targetHr: targetHr ?? this.targetHr,
      rpe: rpe == null ? this.rpe : rpe(),
      time: time ?? this.time,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      blocks: blocks ?? this.blocks,
      done: done ?? this.done,
      notes: notes ?? this.notes,
    );
  }

  static int _counter = 0;

  /// Identifiant unique, basé sur l'horloge et un compteur pour éviter les collisions.
  static String newId() {
    _counter = (_counter + 1) % 1000;
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$stamp${_counter.toString().padLeft(3, '0')}';
  }
}
