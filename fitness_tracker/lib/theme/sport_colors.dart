import 'package:flutter/material.dart';

import '../models/sport.dart';
import 'app_theme.dart';

/// Une couleur par sport, en version claire sur fond sombre et foncée sur fond
/// clair pour rester lisible (au moins 4,5:1) dans les deux thèmes.
extension SportColor on Sport {
  Color get color => (AppColors.palette.isDark ? _onDark : _onLight)[this]!;
}

const Map<Sport, Color> _onDark = {
  Sport.cap: Color(0xFFFB923C),
  Sport.trail: Color(0xFF4ADE80),
  Sport.velo: Color(0xFF60A5FA),
  Sport.ht: Color(0xFF818CF8),
  Sport.nat: Color(0xFF22D3EE),
  Sport.muscu: Color(0xFFF472B6),
  Sport.rando: Color(0xFFA3E635),
  Sport.marche: Color(0xFF2DD4BF),
  Sport.ski: Color(0xFF93C5FD),
  Sport.autre: Color(0xFFA1A1AA),
  Sport.repos: Color(0xFF8E8E96),
};

const Map<Sport, Color> _onLight = {
  Sport.cap: Color(0xFFC2410C),
  Sport.trail: Color(0xFF15803D),
  Sport.velo: Color(0xFF1D4ED8),
  Sport.ht: Color(0xFF4338CA),
  Sport.nat: Color(0xFF0E7490),
  Sport.muscu: Color(0xFFBE185D),
  Sport.rando: Color(0xFF4D7C0F),
  Sport.marche: Color(0xFF0F766E),
  Sport.ski: Color(0xFF0369A1),
  Sport.autre: Color(0xFF52525B),
  Sport.repos: Color(0xFF6B6B6B),
};
