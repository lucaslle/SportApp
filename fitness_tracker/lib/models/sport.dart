/// Discipline d'une séance. Le `code` est la valeur stockée en CSV.
enum Sport {
  cap('CAP', 'Course à pied'),
  trail('TRAIL', 'Trail'),
  velo('VÉLO', 'Vélo'),
  ht('HT', 'Home trainer'),
  nat('NAT', 'Natation'),
  muscu('MUSCU', 'Renforcement'),
  repos('REPOS', 'Repos');

  const Sport(this.code, this.label);

  final String code;
  final String label;

  bool get isRest => this == Sport.repos;

  /// Reconnaît les codes CSV, avec ou sans accent, quelle que soit la casse.
  static Sport? tryParse(String raw) {
    final normalized = raw.trim().toUpperCase().replaceAll('É', 'E');
    if (normalized.isEmpty) return null;
    for (final sport in Sport.values) {
      if (sport.code.replaceAll('É', 'E') == normalized) return sport;
    }
    return switch (normalized) {
      'RUN' || 'RUNNING' || 'COURSE' => Sport.cap,
      'BIKE' || 'CYCLING' => Sport.velo,
      'SWIM' || 'NATATION' => Sport.nat,
      'STRENGTH' || 'RENFO' || 'MUSCULATION' => Sport.muscu,
      'REST' => Sport.repos,
      _ => null,
    };
  }
}
