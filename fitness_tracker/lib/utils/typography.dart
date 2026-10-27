/// Remplace les signes ′ et ″ (minutes, secondes), absents de la police Barlow
/// et affichés avec un espace en trop, par les apostrophes ’ et ” qu'elle contient.
String typographic(String text) => text.replaceAll('′', '’').replaceAll('″', '”');
