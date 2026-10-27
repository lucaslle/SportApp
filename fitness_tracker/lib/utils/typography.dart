/// Remplace les signes ′ et ″ (minutes, secondes), absents de la police Barlow
/// et affichés avec un espace en trop, par les apostrophes ’ et ” qu'elle contient.
String typographic(String text) => text.replaceAll('′', '’').replaceAll('″', '”');

/// Sigles gardés en majuscules par [sentenceCase].
const Set<String> _acronyms = {'RPE', 'FC', 'GPS', 'CAP', 'HT', 'NAT', 'VMA', 'FTP', 'EF', 'D+', 'CSV', 'A', 'B', 'C'};

/// "RÉPARTITION PAR SPORT · 4 SEM." → "Répartition par sport · 4 sem." :
/// les libellés tout en majuscules passent en casse de phrase, sigles conservés.
/// Un texte qui contient déjà des minuscules est rendu tel quel.
String sentenceCase(String text) {
  if (text.toUpperCase() != text || text.toLowerCase() == text) return text;
  final words = text.split(' ').map((word) => _acronyms.contains(word) ? word : word.toLowerCase()).join(' ');
  final first = words.indexOf(RegExp(r'\p{L}', unicode: true));
  if (first < 0 || _acronyms.contains(text.split(' ').first)) return words;
  return words.substring(0, first) + words[first].toUpperCase() + words.substring(first + 1);
}
