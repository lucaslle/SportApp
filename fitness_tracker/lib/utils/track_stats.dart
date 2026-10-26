import '../data/fit_reader.dart';

/// Un kilomètre de la sortie (le dernier peut être partiel).
class KmSplit {
  const KmSplit({required this.index, required this.km, required this.seconds, required this.climb, this.heartRate});

  /// Numéro du kilomètre, à partir de 1.
  final int index;

  /// Longueur réelle du tronçon en km (1 sauf pour le dernier).
  final double km;
  final int seconds;

  /// Dénivelé du tronçon en mètres (positif ou négatif).
  final int climb;
  final int? heartRate;

  /// Allure en secondes par km.
  double get paceSeconds => seconds / km;
}

/// Chiffres tirés d'une trace GPS : dénivelé, fréquence cardiaque, temps au km.
class TrackStats {
  TrackStats._(this.elevationGain, this.averageHeartRate, this.maxHeartRate, this.splits);

  factory TrackStats.of(List<TrackPoint> points) {
    // Hystérésis de 1 m : le bruit du baromètre ne compte pas comme du dénivelé.
    var gain = 0.0;
    double? reference;
    for (final altitude in points.map((p) => p.altitude).whereType<double>()) {
      reference ??= altitude;
      if (altitude > reference + 1) {
        gain += altitude - reference;
        reference = altitude;
      } else if (altitude < reference - 1) {
        reference = altitude;
      }
    }

    final heartRates = points.map((p) => p.heartRate).whereType<int>().toList();
    return TrackStats._(
      gain.round(),
      heartRates.isEmpty ? null : (heartRates.reduce((a, b) => a + b) / heartRates.length).round(),
      heartRates.isEmpty ? null : heartRates.reduce((a, b) => a > b ? a : b),
      _splits(points.where((p) => p.distance != null).toList()),
    );
  }

  final int elevationGain;
  final int? averageHeartRate;
  final int? maxHeartRate;
  final List<KmSplit> splits;

  static List<KmSplit> _splits(List<TrackPoint> points) {
    if (points.length < 2) return const [];
    final splits = <KmSplit>[];
    var start = points.first;
    var heartRates = <int>[];
    for (final point in points.skip(1)) {
      if (point.heartRate != null) heartRates.add(point.heartRate!);
      if (point.distance! - start.distance! >= 1000) {
        splits.add(_split(splits.length + 1, start, point, heartRates));
        start = point;
        heartRates = <int>[];
      }
    }
    // Dernier tronçon gardé s'il fait au moins 100 m.
    if (points.last.distance! - start.distance! >= 100) {
      splits.add(_split(splits.length + 1, start, points.last, heartRates));
    }
    return splits;
  }

  static KmSplit _split(int index, TrackPoint from, TrackPoint to, List<int> heartRates) {
    final meters = to.distance! - from.distance!;
    return KmSplit(
      index: index,
      km: meters >= 1000 ? 1 : meters / 1000,
      seconds: ((to.seconds - from.seconds) * (meters >= 1000 ? 1000 / meters : 1)).round(),
      climb: ((to.altitude ?? 0) - (from.altitude ?? 0)).round(),
      heartRate: heartRates.isEmpty ? null : (heartRates.reduce((a, b) => a + b) / heartRates.length).round(),
    );
  }
}
