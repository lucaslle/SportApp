import '../models/sport.dart';
import '../models/workout_session.dart';
import '../utils/fr_date.dart';
import 'csv_parser.dart';

/// Erreur de lecture d'un fichier CSV de séances, avec le numéro de ligne.
class CsvImportException implements Exception {
  const CsvImportException(this.message, {this.line});

  final String message;
  final int? line;

  @override
  String toString() => line == null ? message : 'Ligne $line : $message';
}

/// Colonnes du fichier CSV, dans l'ordre d'export.
enum CsvColumn {
  date('date', ['date', 'jour', 'day']),
  sport('sport', ['sport', 'discipline', 'type']),
  title('titre', ['titre', 'title', 'seance', 'séance', 'nom', 'name']),
  subtitle('sous_titre', ['sous_titre', 'sous-titre', 'subtitle', 'detail', 'détail', 'description']),
  duration('duree_min', ['duree_min', 'durée_min', 'duree', 'durée', 'duration', 'duration_min', 'minutes']),
  distance('distance_km', ['distance_km', 'distance', 'km', 'volume']),
  targetPace('allure_cible', ['allure_cible', 'allure', 'pace', 'target_pace']),
  targetHr('fc_cible', ['fc_cible', 'fc', 'hr', 'target_hr', 'zone']),
  rpe('rpe', ['rpe', 'effort']),
  time('heure', ['heure', 'time', 'hour']),
  location('lieu', ['lieu', 'location', 'place']),
  tags('tags', ['tags', 'tag', 'etiquettes', 'étiquettes']),
  structure('structure', ['structure', 'blocs', 'blocks']),
  done('faite', ['faite', 'fait', 'done', 'realisee', 'réalisée', 'completed']),
  notes('notes', ['notes', 'note', 'commentaire', 'comment']),
  garminId('garmin_id', ['garmin_id', 'garmin']);

  const CsvColumn(this.header, this.aliases);

  final String header;
  final List<String> aliases;

  static CsvColumn? fromHeader(String raw) {
    final key = _normalizeHeader(raw);
    for (final column in CsvColumn.values) {
      if (column.aliases.any((alias) => _normalizeHeader(alias) == key)) {
        return column;
      }
    }
    return null;
  }

  static String _normalizeHeader(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[àâä]'), 'a')
        .replaceAll(RegExp('[ùûü]'), 'u')
        .replaceAll(RegExp('[îï]'), 'i')
        .replaceAll(RegExp('[ôö]'), 'o')
        .replaceAll(RegExp(r'[\s-]+'), '_');
  }
}

/// Conversion des séances vers/depuis le format CSV de l'application.
///
/// Format d'une ligne (séparateur `;`, en-tête obligatoire) :
/// `date;sport;titre;sous_titre;duree_min;distance_km;allure_cible;fc_cible;
///  rpe;heure;lieu;tags;structure;faite;notes`
///
/// - `date` : `AAAA-MM-JJ` (ou `JJ/MM/AAAA`)
/// - `sport` : CAP, TRAIL, VÉLO, HT, NAT, MUSCU, REPOS
/// - `tags` : séparés par `|`
/// - `structure` : blocs séparés par `|`, champs d'un bloc séparés par `~`
///   (`titre~détail~durée_min~intensité L/M/H`)
/// - `faite` : oui / non
abstract final class SessionCsvCodec {
  static const String delimiter = ';';
  static const String listSeparator = '|';
  static const String blockFieldSeparator = '~';

  static List<String> get header =>
      CsvColumn.values.map((column) => column.header).toList();

  static String encode(Iterable<WorkoutSession> sessions) {
    final rows = <List<String>>[header];
    for (final session in sessions) {
      rows.add(_encodeRow(session));
    }
    return CsvParser.encode(rows, delimiter: delimiter);
  }

  static List<String> _encodeRow(WorkoutSession session) {
    return [
      FrDate.iso(session.date),
      session.sport.code,
      session.title,
      session.subtitle,
      session.durationMin == 0 ? '' : session.durationMin.toString(),
      _formatDistance(session.distanceKm),
      session.targetPace,
      session.targetHr,
      session.rpe?.toString() ?? '',
      session.time,
      session.location,
      session.tags.join(listSeparator),
      encodeBlocks(session.blocks),
      session.done ? 'oui' : 'non',
      session.notes,
      session.garminId,
    ];
  }

  static String _formatDistance(double? km) {
    if (km == null) return '';
    if (km == km.roundToDouble()) return km.toInt().toString();
    return km.toStringAsFixed(1);
  }

  static String encodeBlocks(List<SessionBlock> blocks) {
    return blocks.map((block) {
      final cleanTitle = _stripSeparators(block.title);
      final cleanDetail = _stripSeparators(block.detail);
      return '$cleanTitle$blockFieldSeparator$cleanDetail'
          '$blockFieldSeparator${block.durationMin}'
          '$blockFieldSeparator${block.intensity.code}';
    }).join(' $listSeparator ');
  }

  static String _stripSeparators(String value) =>
      value.replaceAll(listSeparator, '/').replaceAll(blockFieldSeparator, '-');

  static List<SessionBlock> decodeBlocks(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw.split(listSeparator).map((chunk) {
      final parts = chunk.split(blockFieldSeparator).map((part) => part.trim()).toList();
      return SessionBlock(
        title: parts.isNotEmpty ? parts[0] : '',
        detail: parts.length > 1 ? parts[1] : '',
        durationMin: parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
        intensity: parts.length > 3 ? BlockIntensity.fromCode(parts[3]) : BlockIntensity.medium,
      );
    }).where((block) => block.title.isNotEmpty).toList();
  }

  /// Lit un fichier complet. Lève [CsvImportException] à la première erreur.
  static List<WorkoutSession> decode(String text) {
    final rows = CsvParser.parse(text);
    if (rows.isEmpty) {
      throw const CsvImportException('Le fichier est vide.');
    }
    final columns = <int, CsvColumn>{};
    for (var i = 0; i < rows.first.length; i++) {
      final column = CsvColumn.fromHeader(rows.first[i]);
      if (column != null) columns[i] = column;
    }
    final present = columns.values.toSet();
    for (final required in const [CsvColumn.date, CsvColumn.sport, CsvColumn.title]) {
      if (!present.contains(required)) {
        throw CsvImportException(
          'Colonne « ${required.header} » introuvable dans l\'en-tête.',
          line: 1,
        );
      }
    }

    final sessions = <WorkoutSession>[];
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final values = <CsvColumn, String>{};
      columns.forEach((index, column) {
        values[column] = index < row.length ? row[index].trim() : '';
      });
      sessions.add(_decodeRow(values, line: rowIndex + 1));
    }
    return sessions;
  }

  static WorkoutSession _decodeRow(Map<CsvColumn, String> values, {required int line}) {
    String read(CsvColumn column) => values[column] ?? '';

    final date = FrDate.tryParse(read(CsvColumn.date));
    if (date == null) {
      throw CsvImportException(
        'Date invalide « ${read(CsvColumn.date)} » (attendu AAAA-MM-JJ).',
        line: line,
      );
    }
    final sport = Sport.tryParse(read(CsvColumn.sport));
    if (sport == null) {
      throw CsvImportException(
        'Sport inconnu « ${read(CsvColumn.sport)} » '
        '(attendu ${Sport.values.map((sport) => sport.code).join(', ')}).',
        line: line,
      );
    }
    final title = read(CsvColumn.title);
    if (title.isEmpty) {
      throw CsvImportException('Le titre est obligatoire.', line: line);
    }
    final duration = parseDurationMinutes(read(CsvColumn.duration));
    if (duration == null && read(CsvColumn.duration).isNotEmpty) {
      throw CsvImportException(
        'Durée invalide « ${read(CsvColumn.duration)} » (minutes entières attendues).',
        line: line,
      );
    }
    final distance = _parseDouble(read(CsvColumn.distance));
    if (distance == null && read(CsvColumn.distance).isNotEmpty) {
      throw CsvImportException(
        'Distance invalide « ${read(CsvColumn.distance)} ».',
        line: line,
      );
    }
    final rpe = _parseInt(read(CsvColumn.rpe));
    if (rpe != null && (rpe < 1 || rpe > 10)) {
      throw CsvImportException('RPE hors limites (1 à 10).', line: line);
    }

    return WorkoutSession(
      id: WorkoutSession.newId(),
      date: date,
      sport: sport,
      title: title,
      subtitle: read(CsvColumn.subtitle),
      durationMin: duration ?? 0,
      distanceKm: distance,
      targetPace: read(CsvColumn.targetPace),
      targetHr: read(CsvColumn.targetHr),
      rpe: rpe,
      time: read(CsvColumn.time),
      location: read(CsvColumn.location),
      tags: _parseTags(read(CsvColumn.tags)),
      blocks: decodeBlocks(read(CsvColumn.structure)),
      done: parseBool(read(CsvColumn.done)),
      notes: read(CsvColumn.notes),
      garminId: read(CsvColumn.garminId),
    );
  }

  static List<String> _parseTags(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[|,]'))
        .map((tag) => tag.trim().toUpperCase())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  static int? _parseInt(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d-]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  /// Accepte "55", "55 min", "55′", "1h30", "1h", "01:30".
  static int? parseDurationMinutes(String raw) {
    final text = raw.trim().toLowerCase();
    if (text.isEmpty) return null;
    final hoursMinutes = RegExp(r'^(\d{1,2})\s*[h:]\s*(\d{0,2})$').firstMatch(text);
    if (hoursMinutes != null) {
      final hours = int.parse(hoursMinutes.group(1)!);
      final minutes = int.tryParse(hoursMinutes.group(2)!) ?? 0;
      return hours * 60 + minutes;
    }
    final minutesOnly = RegExp(r'^(\d+)\s*(min|mn|m|′|\x27)?$').firstMatch(text);
    if (minutesOnly != null) return int.parse(minutesOnly.group(1)!);
    return null;
  }

  static double? _parseDouble(String raw) {
    final cleaned = raw.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.\-]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static bool parseBool(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'oui' || 'o' || 'yes' || 'y' || 'true' || '1' || 'x' || 'faite' || 'fait' => true,
      _ => false,
    };
  }
}
