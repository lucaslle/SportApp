/// Lecture/écriture CSV minimaliste (RFC 4180) : guillemets, retours à la ligne
/// dans les champs, BOM UTF-8 et détection automatique du séparateur.
abstract final class CsvParser {
  static const List<String> _candidateDelimiters = [';', ',', '\t'];

  /// Devine le séparateur à partir de la première ligne non vide.
  static String detectDelimiter(String text) {
    final firstLine = text
        .split(RegExp(r'\r?\n'))
        .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');
    var best = ';';
    var bestCount = -1;
    for (final delimiter in _candidateDelimiters) {
      final count = _countOutsideQuotes(firstLine, delimiter);
      if (count > bestCount) {
        best = delimiter;
        bestCount = count;
      }
    }
    return best;
  }

  static int _countOutsideQuotes(String line, String delimiter) {
    var count = 0;
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (!inQuotes && char == delimiter) {
        count++;
      }
    }
    return count;
  }

  /// Découpe [text] en lignes de champs. Les lignes vides sont ignorées.
  static List<List<String>> parse(String text, {String? delimiter}) {
    var source = text;
    if (source.startsWith('﻿')) source = source.substring(1);
    final separator = delimiter ?? detectDelimiter(source);

    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var fieldStarted = false;

    void endField() {
      row.add(field.toString());
      field.clear();
      fieldStarted = false;
    }

    void endRow() {
      endField();
      final isBlank = row.every((value) => value.trim().isEmpty);
      if (!isBlank) rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (inQuotes) {
        if (char == '"') {
          final isEscapedQuote = i + 1 < source.length && source[i + 1] == '"';
          if (isEscapedQuote) {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(char);
        }
        continue;
      }
      if (char == '"' && !fieldStarted) {
        inQuotes = true;
        fieldStarted = true;
      } else if (char == separator) {
        endField();
      } else if (char == '\r') {
        continue;
      } else if (char == '\n') {
        endRow();
      } else {
        field.write(char);
        fieldStarted = true;
      }
    }
    if (fieldStarted || row.isNotEmpty) endRow();
    return rows;
  }

  /// Sérialise [rows] avec [delimiter], fins de ligne CRLF et BOM pour Excel.
  static String encode(List<List<String>> rows, {String delimiter = ';'}) {
    final buffer = StringBuffer('﻿');
    for (final row in rows) {
      buffer.write(row.map((value) => _quote(value, delimiter)).join(delimiter));
      buffer.write('\r\n');
    }
    return buffer.toString();
  }

  static String _quote(String value, String delimiter) {
    final needsQuotes = value.contains(delimiter) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
