import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Persistance du plan : le plan complet est conservé tel quel au format CSV,
/// ce qui garantit que l'export reproduit exactement ce qui est stocké.
abstract class PlanStorage {
  /// Retourne le CSV stocké, ou `null` si rien n'a encore été enregistré.
  Future<String?> read();

  Future<void> write(String csv);

  /// Fichier sur disque quand la plateforme le permet, mémoire sinon (web).
  static PlanStorage forPlatform() {
    if (kIsWeb) return MemoryPlanStorage();
    return FilePlanStorage();
  }
}

class MemoryPlanStorage implements PlanStorage {
  String? _csv;

  @override
  Future<String?> read() async => _csv;

  @override
  Future<void> write(String csv) async => _csv = csv;
}

class FilePlanStorage implements PlanStorage {
  FilePlanStorage({this.fileName = 'plan_seances.csv'});

  final String fileName;

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  @override
  Future<String?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return await file.readAsString();
    } on Exception catch (error) {
      debugPrint('Lecture du plan impossible : $error');
      return null;
    }
  }

  @override
  Future<void> write(String csv) async {
    final file = await _file();
    await file.writeAsString(csv, flush: true);
  }
}
