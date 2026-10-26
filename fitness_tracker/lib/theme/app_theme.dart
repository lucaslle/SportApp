import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Couleurs d'un thème. Les noms viennent de la maquette sombre : `text` est la
/// couleur du texte principal, `onLight` celle du texte posé sur un fond `text`.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.card,
    required this.cardDeep,
    required this.cardSelected,
    required this.border,
    required this.borderSoft,
    required this.borderMid,
    required this.borderStrong,
    required this.borderDashed,
    required this.divider,
    required this.track,
    required this.text,
    required this.textSoft,
    required this.textPill,
    required this.textFilter,
    required this.label,
    required this.muted,
    required this.mutedDark,
    required this.dim,
    required this.dimmer,
    required this.onLight,
    required this.onLightMuted,
    required this.onLightDim,
    required this.barOff,
    required this.blockLow,
    required this.blockMedium,
    required this.onLightTrack,
    required this.chartBar,
    required this.chartBarSoft,
    required this.glass,
    required this.shadow,
    required this.splitBar,
    required this.isDark,
  });

  final Color background;
  final Color card;
  final Color cardDeep;
  final Color cardSelected;
  final Color border;
  final Color borderSoft;
  final Color borderMid;
  final Color borderStrong;
  final Color borderDashed;
  final Color divider;
  final Color track;
  final Color text;
  final Color textSoft;
  final Color textPill;
  final Color textFilter;
  final Color label;
  final Color muted;
  final Color mutedDark;
  final Color dim;
  final Color dimmer;
  final Color onLight;
  final Color onLightMuted;
  final Color onLightDim;
  final Color barOff;
  final Color blockLow;
  final Color blockMedium;
  /// Piste des barres de progression sur les cartes inversées.
  final Color onLightTrack;
  /// Barres de graphique ordinaires.
  final Color chartBar;
  /// Barres de graphique atténuées.
  final Color chartBarSoft;
  /// Fond translucide de la barre d'onglets.
  final Color glass;
  /// Ombre portée.
  final Color shadow;
  /// Barres des temps au km.
  final Color splitBar;
  final bool isDark;

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0B0B0B),
    card: Color(0xFF141414),
    cardDeep: Color(0xFF101010),
    cardSelected: Color(0xFF1F1F1F),
    border: Color(0xFF242424),
    borderSoft: Color(0xFF1C1C1C),
    borderMid: Color(0xFF2A2A2A),
    borderStrong: Color(0xFF2F2F2F),
    borderDashed: Color(0xFF3A3A3A),
    divider: Color(0xFF262626),
    track: Color(0xFF202020),
    text: Color(0xFFF5F5F5),
    textSoft: Color(0xFFD4D4D4),
    textPill: Color(0xFFC4C4C4),
    textFilter: Color(0xFFB4B4B4),
    label: Color(0xFFA6A6A6),
    muted: Color(0xFF9E9E9E),
    mutedDark: Color(0xFF969696),
    dim: Color(0xFF8C8C8C),
    dimmer: Color(0xFF757575),
    onLight: Color(0xFF0B0B0B),
    onLightMuted: Color(0xFF4A4A4A),
    onLightDim: Color(0xFF6A6A6A),
    barOff: Color(0xFF333333),
    blockLow: Color(0xFF2A2A2A),
    blockMedium: Color(0xFF4A4A4A),
    onLightTrack: Color(0xFFD6D6D6),
    chartBar: Color(0xFF4F4F4F),
    chartBarSoft: Color(0xFF2D2D2D),
    glass: Color(0xB81A1A1A),
    shadow: Color(0x8C000000),
    splitBar: Color(0xFFE8E8E8),
    isDark: true,
  );

  static const AppPalette light = AppPalette(
    background: Color(0xFFF4F4F4),
    card: Color(0xFFFFFFFF),
    cardDeep: Color(0xFFEDEDED),
    cardSelected: Color(0xFFE6E6E6),
    border: Color(0xFFDDDDDD),
    borderSoft: Color(0xFFE8E8E8),
    borderMid: Color(0xFFD4D4D4),
    borderStrong: Color(0xFFCCCCCC),
    borderDashed: Color(0xFFB8B8B8),
    divider: Color(0xFFDEDEDE),
    track: Color(0xFFE2E2E2),
    text: Color(0xFF0B0B0B),
    textSoft: Color(0xFF2B2B2B),
    textPill: Color(0xFF3A3A3A),
    textFilter: Color(0xFF444444),
    label: Color(0xFF555555),
    muted: Color(0xFF5C5C5C),
    mutedDark: Color(0xFF616161),
    dim: Color(0xFF6B6B6B),
    dimmer: Color(0xFF8A8A8A),
    onLight: Color(0xFFF5F5F5),
    onLightMuted: Color(0xFFC4C4C4),
    onLightDim: Color(0xFFA6A6A6),
    barOff: Color(0xFFD0D0D0),
    blockLow: Color(0xFFE0E0E0),
    blockMedium: Color(0xFFBDBDBD),
    onLightTrack: Color(0xFF3A3A3A),
    chartBar: Color(0xFFB0B0B0),
    chartBarSoft: Color(0xFFD8D8D8),
    glass: Color(0xCCFFFFFF),
    shadow: Color(0x1F000000),
    splitBar: Color(0xFF2B2B2B),
    isDark: false,
  );
}

/// Couleurs du thème courant, changées par [use] avant de reconstruire l'app.
abstract final class AppColors {
  static AppPalette _palette = AppPalette.dark;

  static AppPalette get palette => _palette;

  static void use(AppPalette palette) => _palette = palette;

  static Color get background => _palette.background;
  static Color get card => _palette.card;
  static Color get cardDeep => _palette.cardDeep;
  static Color get cardSelected => _palette.cardSelected;
  static Color get border => _palette.border;
  static Color get borderSoft => _palette.borderSoft;
  static Color get borderMid => _palette.borderMid;
  static Color get borderStrong => _palette.borderStrong;
  static Color get borderDashed => _palette.borderDashed;
  static Color get divider => _palette.divider;
  static Color get track => _palette.track;
  static Color get text => _palette.text;
  static Color get textSoft => _palette.textSoft;
  static Color get textPill => _palette.textPill;
  static Color get textFilter => _palette.textFilter;
  static Color get label => _palette.label;
  static Color get muted => _palette.muted;
  static Color get mutedDark => _palette.mutedDark;
  static Color get dim => _palette.dim;
  static Color get dimmer => _palette.dimmer;
  static Color get onLight => _palette.onLight;
  static Color get onLightMuted => _palette.onLightMuted;
  static Color get onLightDim => _palette.onLightDim;
  static Color get barOff => _palette.barOff;
  static Color get blockLow => _palette.blockLow;
  static Color get blockMedium => _palette.blockMedium;
  static Color get onLightTrack => _palette.onLightTrack;
  static Color get chartBar => _palette.chartBar;
  static Color get chartBarSoft => _palette.chartBarSoft;
  static Color get glass => _palette.glass;
  static Color get shadow => _palette.shadow;
  static Color get splitBar => _palette.splitBar;
}

/// Styles typographiques : Archivo pour le texte, JetBrains Mono pour les données.
abstract final class AppText {
  /// Les tailles de la maquette (8 à 11 px) sont trop petites sur téléphone :
  /// tout texte passe à 11 px minimum, les petites tailles gagnent 1,5 px.
  static double _readable(double size) => size < 12 ? (size + 1.5).clamp(11, 12) : size;

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacingEm,
    double? height,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.archivo(
      fontSize: _readable(size),
      fontWeight: weight,
      color: color ?? AppColors.text,
      letterSpacing: letterSpacingEm == null ? null : _readable(size) * letterSpacingEm,
      height: height,
      fontStyle: fontStyle,
    );
  }

  static TextStyle mono({
    double size = 10,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacingEm,
    double? height,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: _readable(size),
      fontWeight: weight,
      color: color ?? AppColors.text,
      letterSpacing: letterSpacingEm == null ? null : _readable(size) * letterSpacingEm,
      height: height,
    );
  }

  /// Petit libellé mono gris, majuscules espacées (ex. "SÉANCE DU JOUR").
  static TextStyle eyebrow({
    double size = 10,
    Color? color,
    double letterSpacingEm = .2,
  }) =>
      mono(size: size, color: color ?? AppColors.mutedDark, letterSpacingEm: letterSpacingEm);

  static TextStyle screenTitle({double size = 24}) =>
      sans(size: size, weight: FontWeight.w700, letterSpacingEm: -.02);
}

ThemeData buildAppTheme() {
  final dark = AppColors.palette.isDark;
  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      error: const Color(0xFFD32F2F),
      onError: Colors.white,
      onSecondary: AppColors.onLight,
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
    highlightColor: AppColors.text.withValues(alpha: .04),
    dividerColor: AppColors.border,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: AppText.sans(size: 13, color: AppColors.onLight),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.text,
      selectionColor: AppColors.text.withValues(alpha: .2),
      selectionHandleColor: AppColors.text,
    ),
  );
}
