import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette noir & blanc de la maquette.
abstract final class AppColors {
  static const Color background = Color(0xFF0B0B0B);
  static const Color card = Color(0xFF141414);
  static const Color cardDeep = Color(0xFF101010);
  static const Color cardSelected = Color(0xFF1F1F1F);
  static const Color border = Color(0xFF242424);
  static const Color borderSoft = Color(0xFF1C1C1C);
  static const Color borderMid = Color(0xFF2A2A2A);
  static const Color borderStrong = Color(0xFF2F2F2F);
  static const Color borderDashed = Color(0xFF3A3A3A);
  static const Color divider = Color(0xFF262626);
  static const Color track = Color(0xFF202020);
  static const Color text = Color(0xFFF5F5F5);
  static const Color textSoft = Color(0xFFD4D4D4);
  static const Color textPill = Color(0xFFC4C4C4);
  static const Color textFilter = Color(0xFFB4B4B4);
  static const Color label = Color(0xFFA6A6A6);
  static const Color muted = Color(0xFF9E9E9E);
  static const Color mutedDark = Color(0xFF969696);
  static const Color dim = Color(0xFF8C8C8C);
  static const Color dimmer = Color(0xFF757575);
  static const Color onLight = Color(0xFF0B0B0B);
  static const Color onLightMuted = Color(0xFF4A4A4A);
  static const Color onLightDim = Color(0xFF6A6A6A);
  static const Color barOff = Color(0xFF333333);
  static const Color blockLow = Color(0xFF2A2A2A);
  static const Color blockMedium = Color(0xFF4A4A4A);
}

/// Styles typographiques : Archivo pour le texte, JetBrains Mono pour les données.
abstract final class AppText {
  /// Les tailles de la maquette (8 à 11 px) sont trop petites sur téléphone :
  /// tout texte passe à 11 px minimum, les petites tailles gagnent 1,5 px.
  static double _readable(double size) => size < 12 ? (size + 1.5).clamp(11, 12) : size;

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double? letterSpacingEm,
    double? height,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.archivo(
      fontSize: _readable(size),
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacingEm == null ? null : _readable(size) * letterSpacingEm,
      height: height,
      fontStyle: fontStyle,
    );
  }

  static TextStyle mono({
    double size = 10,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double? letterSpacingEm,
    double? height,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: _readable(size),
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacingEm == null ? null : _readable(size) * letterSpacingEm,
      height: height,
    );
  }

  /// Petit libellé mono gris, majuscules espacées (ex. "SÉANCE DU JOUR").
  static TextStyle eyebrow({
    double size = 10,
    Color color = AppColors.mutedDark,
    double letterSpacingEm = .2,
  }) =>
      mono(size: size, color: color, letterSpacingEm: letterSpacingEm);

  static TextStyle screenTitle({double size = 24}) =>
      sans(size: size, weight: FontWeight.w700, letterSpacingEm: -.02);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.text,
      onPrimary: AppColors.onLight,
      surface: AppColors.background,
      onSurface: AppColors.text,
      secondary: AppColors.textSoft,
      outline: AppColors.border,
    ),
    textTheme: GoogleFonts.archivoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.white.withValues(alpha: .04),
    dividerColor: AppColors.border,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: AppText.sans(size: 13, color: AppColors.onLight),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.text,
      selectionColor: Color(0x33F5F5F5),
      selectionHandleColor: AppColors.text,
    ),
  );
}
