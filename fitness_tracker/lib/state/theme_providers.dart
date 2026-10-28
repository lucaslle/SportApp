import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plan_storage.dart';
import '../theme/app_theme.dart';

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

final accentStorageProvider = Provider<PlanStorage>((ref) => PlanStorage.forPlatform(fileName: 'accent.txt'));

/// Couleur d'accent choisie, enregistrée sur l'appareil.
final accentProvider = NotifierProvider<AccentNotifier, AppAccent>(AccentNotifier.new);

class AccentNotifier extends Notifier<AppAccent> {
  @override
  AppAccent build() {
    _load();
    return AppAccent.orange;
  }

  Future<void> _load() async {
    final stored = (await ref.read(accentStorageProvider).read())?.trim();
    final saved = AppAccent.values.where((accent) => accent.name == stored).firstOrNull;
    if (saved != null) state = saved;
  }

  Future<void> choose(AppAccent accent) async {
    state = accent;
    await ref.read(accentStorageProvider).write(accent.name);
  }
}
