/// Formatage des dates en français sans dépendance à `intl`.
abstract final class FrDate {
  static const List<String> dayShort = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
  static const List<String> dayLetter = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const List<String> dayLong = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  static const List<String> dayAbbrev = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const List<String> monthLong = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  static const List<String> monthShort = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  static DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Lundi de la semaine contenant [date].
  static DateTime mondayOf(DateTime date) {
    final day = dateOnly(date);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  /// Nombre de jours civils entre deux dates, insensible aux changements
  /// d'heure (une différence de dates locales perd une heure au passage à
  /// l'heure d'été et fausse `inDays`).
  static int daysBetween(DateTime from, DateTime to) {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    return end.difference(start).inDays;
  }

  /// Numéro de semaine ISO 8601.
  static int isoWeek(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
    final firstDay = DateTime.utc(thursday.year, 1, 1);
    return 1 + (thursday.difference(firstDay).inDays ~/ 7);
  }

  /// "Lundi 14 septembre"
  static String longDay(DateTime date) =>
      '${dayLong[date.weekday - 1]} ${date.day} ${monthLong[date.month - 1]}';

  /// "Lundi 14 sept."
  static String longDayShortMonth(DateTime date) =>
      '${dayLong[date.weekday - 1]} ${date.day} ${monthShort[date.month - 1]}';

  /// "Lun 14 sept."
  static String abbrevDay(DateTime date) =>
      '${dayAbbrev[date.weekday - 1]} ${date.day} ${monthShort[date.month - 1]}';

  /// "14 → 20 sept." ou "28 sept. → 4 oct."
  static String weekRange(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    if (monday.month == sunday.month) {
      return '${monday.day} → ${sunday.day} ${monthShort[sunday.month - 1]}';
    }
    return '${monday.day} ${monthShort[monday.month - 1]} → '
        '${sunday.day} ${monthShort[sunday.month - 1]}';
  }

  /// "septembre 2026"
  static String monthYear(DateTime date) => '${monthLong[date.month - 1]} ${date.year}';

  /// "2026-09-14" (format stocké en CSV).
  static String iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Accepte "2026-09-14", "14/09/2026" et "14-09-2026".
  static DateTime? tryParse(String raw) {
    final text = raw.trim();
    final isoMatch = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(text);
    if (isoMatch != null) {
      return _build(isoMatch.group(1)!, isoMatch.group(2)!, isoMatch.group(3)!);
    }
    final frMatch = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(text);
    if (frMatch != null) {
      return _build(frMatch.group(3)!, frMatch.group(2)!, frMatch.group(1)!);
    }
    return null;
  }

  static DateTime? _build(String year, String month, String day) {
    final y = int.parse(year);
    final m = int.parse(month);
    final d = int.parse(day);
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, m, d);
    return date.month == m && date.day == d ? date : null;
  }
}
