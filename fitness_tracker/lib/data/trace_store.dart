import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'fit_reader.dart';

/// Traces GPS simplifiées, un fichier texte compressé par activité Garmin
/// (`traces/<garminId>.csv.gz`) : `secondes;lat;lon;altitude;fc;distance`.
class TraceStore {
  const TraceStore();

  Future<File> _file(String garminId) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}traces${Platform.pathSeparator}$garminId.csv.gz');
  }

  Future<bool> exists(String garminId) async => !kIsWeb && await (await _file(garminId)).exists();

  Future<void> write(String garminId, List<TrackPoint> points) async {
    final file = await _file(garminId);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(gzip.encode(encode(points).codeUnits), flush: true);
  }

  /// Trace de l'activité, ou liste vide si elle n'existe pas ou est illisible.
  Future<List<TrackPoint>> read(String garminId) async {
    if (kIsWeb || garminId.isEmpty) return const [];
    try {
      final file = await _file(garminId);
      if (!await file.exists()) return const [];
      return decode(String.fromCharCodes(gzip.decode(await file.readAsBytes())));
    } on Exception catch (error) {
      debugPrint('Trace $garminId illisible : $error');
      return const [];
    }
  }

  static String encode(List<TrackPoint> points) => points
      .map((p) => '${p.seconds};${p.lat.toStringAsFixed(5)};${p.lon.toStringAsFixed(5)};'
          '${p.altitude?.round() ?? ''};${p.heartRate ?? ''};${p.distance?.round() ?? ''}')
      .join('\n');

  static List<TrackPoint> decode(String text) {
    final points = <TrackPoint>[];
    for (final line in text.split('\n')) {
      final parts = line.split(';');
      if (parts.length < 6) continue;
      final seconds = int.tryParse(parts[0]);
      final lat = double.tryParse(parts[1]);
      final lon = double.tryParse(parts[2]);
      if (seconds == null || lat == null || lon == null) continue;
      points.add(TrackPoint(
        seconds: seconds,
        lat: lat,
        lon: lon,
        altitude: double.tryParse(parts[3]),
        heartRate: int.tryParse(parts[4]),
        distance: double.tryParse(parts[5]),
      ));
    }
    return points;
  }
}
