import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plan_storage.dart';

final themeStorageProvider =
    Provider<PlanStorage>((ref) => PlanStorage.forPlatform(fileName: 'apparence.txt'));

/// Apparence choisie : système, clair ou sombre, enregistrée sur l'appareil.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final stored = (await ref.read(themeStorageProvider).read())?.trim();
    final saved = ThemeMode.values.where((mode) => mode.name == stored).firstOrNull;
    if (saved != null) state = saved;
  }

  Future<void> choose(ThemeMode mode) async {
    state = mode;
    await ref.read(themeStorageProvider).write(mode.name);
  }
}
