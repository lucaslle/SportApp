import 'dart:io';
import 'dart:typed_data';

/// Un point de trace GPS.
class TrackPoint {
  const TrackPoint({
    required this.seconds,
    required this.lat,
    required this.lon,
    this.altitude,
    this.heartRate,
    this.distance,
  });

  /// Secondes écoulées depuis le premier point.
  final int seconds;
  final double lat;
  final double lon;

  /// Mètres.
  final double? altitude;
  final int? heartRate;

  /// Mètres parcourus depuis le départ.
  final double? distance;
}

/// Lecture minimale des fichiers .FIT Garmin : seuls les messages « record »
/// (n° 20) sont décodés, pour en tirer la trace GPS.
abstract final class FitReader {
  static const double _semicircle = 180 / 2147483648;

  /// Extrait le premier .fit d'une archive ZIP (format renvoyé par Garmin) ;
  /// renvoie [bytes] tel quel si ce n'est pas un ZIP. Les tailles sont lues
  /// dans le répertoire central : Garmin les omet des en-têtes locaux.
  static Uint8List unzip(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    if (bytes.length < 22 || data.getUint32(0, Endian.little) != 0x04034b50) return bytes;
    var eocd = bytes.length - 22;
    while (eocd >= 0 && data.getUint32(eocd, Endian.little) != 0x06054b50) {
      eocd--;
    }
    if (eocd < 0) throw const FormatException('Archive ZIP incomplète.');
    final entries = data.getUint16(eocd + 10, Endian.little);
    var offset = data.getUint32(eocd + 16, Endian.little);
    for (var i = 0; i < entries; i++) {
      final method = data.getUint16(offset + 10, Endian.little);
      final compressedSize = data.getUint32(offset + 20, Endian.little);
      final nameLength = data.getUint16(offset + 28, Endian.little);
      final extraLength = data.getUint16(offset + 30, Endian.little);
      final commentLength = data.getUint16(offset + 32, Endian.little);
      final localHeader = data.getUint32(offset + 42, Endian.little);
      final name = String.fromCharCodes(bytes.sublist(offset + 46, offset + 46 + nameLength));
      if (name.toLowerCase().endsWith('.fit')) {
        final start = localHeader +
            30 +
            data.getUint16(localHeader + 26, Endian.little) +
            data.getUint16(localHeader + 28, Endian.little);
        final content = bytes.sublist(start, start + compressedSize);
        if (method == 0) return content;
        if (method == 8) return Uint8List.fromList(ZLibDecoder(raw: true).convert(content));
        throw const FormatException('Compression ZIP non gérée.');
      }
      offset += 46 + nameLength + extraLength + commentLength;
    }
    throw const FormatException('Aucun fichier .fit dans l\'archive.');
  }

  /// Points GPS du fichier, un point par message « record » positionné.
  static List<TrackPoint> records(Uint8List fit) {
    final data = ByteData.sublistView(fit);
    final headerSize = fit[0];
    final end = headerSize + data.getUint32(4, Endian.little);
    final definitions = <int, _Definition>{};
    final points = <TrackPoint>[];
    int? firstTimestamp;
    var lastTimestamp = 0;
    var pos = headerSize;

    while (pos < end && pos < fit.length) {
      final header = fit[pos++];
      int local;
      int? timestamp;
      if (header & 0x80 != 0) {
        // En-tête à horodatage compressé : décalage de 5 bits sur le dernier horodatage.
        local = (header >> 5) & 0x3;
        final offset = header & 0x1F;
        timestamp = (lastTimestamp & ~0x1F) + offset;
        if (offset < (lastTimestamp & 0x1F)) timestamp += 0x20;
      } else {
        local = header & 0x0F;
        if (header & 0x40 != 0) {
          final endian = fit[pos + 1] == 0 ? Endian.little : Endian.big;
          final global = data.getUint16(pos + 2, endian);
          final count = fit[pos + 4];
          pos += 5;
          final fields = [for (var i = 0; i < count; i++) (fit[pos + 3 * i], fit[pos + 3 * i + 1])];
          pos += 3 * count;
          var developerSize = 0;
          if (header & 0x20 != 0) {
            final developerCount = fit[pos++];
            for (var i = 0; i < developerCount; i++) {
              developerSize += fit[pos + 3 * i + 1];
            }
            pos += 3 * developerCount;
          }
          definitions[local] = _Definition(global, endian, fields, developerSize);
          continue;
        }
      }

      final definition = definitions[local];
      if (definition == null) throw const FormatException('Fichier FIT invalide.');
      if (definition.global == 20) {
        int? lat, lon, heartRate;
        double? altitude, distance;
        var offset = pos;
        for (final (number, size) in definition.fields) {
          switch ((number, size)) {
            case (253, 4):
              timestamp = data.getUint32(offset, definition.endian);
            case (0, 4):
              lat = _sint32(data.getInt32(offset, definition.endian));
            case (1, 4):
              lon = _sint32(data.getInt32(offset, definition.endian));
            case (2, 2):
              final raw = data.getUint16(offset, definition.endian);
              if (raw != 0xFFFF) altitude ??= raw / 5 - 500;
            case (78, 4):
              final raw = data.getUint32(offset, definition.endian);
              if (raw != 0xFFFFFFFF) altitude = raw / 5 - 500;
            case (3, 1):
              if (fit[offset] != 0xFF) heartRate = fit[offset];
            case (5, 4):
              final raw = data.getUint32(offset, definition.endian);
              if (raw != 0xFFFFFFFF) distance = raw / 100;
          }
          offset += size;
        }
        if (timestamp != null) lastTimestamp = timestamp;
        if (lat != null && lon != null && timestamp != null) {
          firstTimestamp ??= timestamp;
          points.add(TrackPoint(
            seconds: timestamp - firstTimestamp,
            lat: lat * _semicircle,
            lon: lon * _semicircle,
            altitude: altitude,
            heartRate: heartRate,
            distance: distance,
          ));
        }
      } else if (timestamp != null) {
        lastTimestamp = timestamp;
      }
      pos += definition.size;
    }
    return points;
  }

  static int? _sint32(int value) => value == 0x7FFFFFFF ? null : value;

  /// Garde au plus un point toutes les [everySeconds] secondes, plus le dernier.
  static List<TrackPoint> simplify(List<TrackPoint> points, {int everySeconds = 5}) {
    if (points.length < 3) return points;
    final kept = <TrackPoint>[points.first];
    for (final point in points.skip(1)) {
      if (point.seconds - kept.last.seconds >= everySeconds) kept.add(point);
    }
    if (kept.last != points.last) kept.add(points.last);
    return kept;
  }
}

class _Definition {
  _Definition(this.global, this.endian, this.fields, this.developerSize);

  final int global;
  final Endian endian;
  final List<(int, int)> fields;
  final int developerSize;

  int get size => fields.fold(developerSize, (sum, field) => sum + field.$2);
}
