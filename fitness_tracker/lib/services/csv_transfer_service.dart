import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Résultat d'un export : emplacement choisi, ou simple confirmation.
class ExportOutcome {
  const ExportOutcome({required this.saved, this.location});

  final bool saved;
  final Uri? location;
}

/// Ouvre les boîtes de dialogue système pour lire ou écrire un fichier CSV.
class CsvTransferService {
  const CsvTransferService();

  /// Retourne le contenu texte du fichier choisi, ou `null` si annulé.
  Future<String?> pickCsvText() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      dialogTitle: 'Importer un plan de séances',
    );
    if (files.isEmpty) return null;
    final bytes = await files.first.readAsBytes();
    return _decodeText(bytes);
  }

  /// Décode en UTF-8, avec repli Latin-1 pour les exports Excel anciens.
  String _decodeText(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  /// Propose d'enregistrer [csv] sous [fileName].
  Future<ExportOutcome> saveCsv({required String fileName, required String csv}) async {
    final location = await FilePicker.saveFile(
      dialogTitle: 'Exporter le plan de séances',
      fileName: fileName,
      mimeType: 'text/csv',
      bytes: Uint8List.fromList(utf8.encode(csv)),
    );
    if (location == null) return const ExportOutcome(saved: false);
    return ExportOutcome(saved: true, location: location);
  }
}
